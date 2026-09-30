import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("workbox-precaching", () => ({
  cleanupOutdatedCaches: vi.fn(),
  precacheAndRoute: vi.fn(),
}));

vi.mock("workbox-core", () => ({ clientsClaim: vi.fn() }));

const ORIGIN = "https://fleetyards.net";

type Listener = (event: Record<string, unknown>) => void;

const worker = () => {
  const listeners: Record<string, Listener> = {};
  const scope = {
    __WB_MANIFEST: [],
    location: { origin: ORIGIN },
    registration: {
      showNotification: vi.fn().mockResolvedValue(undefined),
      pushManager: { subscribe: vi.fn() },
    },
    clients: {
      matchAll: vi.fn().mockResolvedValue([]),
      openWindow: vi.fn().mockResolvedValue(null),
    },
    skipWaiting: vi.fn().mockResolvedValue(undefined),
    addEventListener: (type: string, listener: Listener) => {
      listeners[type] = listener;
    },
  };

  return { scope, listeners };
};

let current: ReturnType<typeof worker>;

// The event's work is whatever it handed to waitUntil.
const dispatch = async (type: string, event: Record<string, unknown>) => {
  const pending: Promise<unknown>[] = [];
  current.listeners[type]({
    ...event,
    waitUntil: (promise: Promise<unknown>) => pending.push(promise),
  });
  return Promise.allSettled(pending);
};

beforeEach(async () => {
  current = worker();
  vi.stubGlobal("self", current.scope);
  vi.resetModules();
  await import("./sw");
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("push", () => {
  it("shows the pushed notification", async () => {
    await dispatch("push", {
      data: {
        text: () =>
          JSON.stringify({
            title: "Invited",
            body: "Join us",
            url: `${ORIGIN}/fleets/invites`,
            tag: "fleet_invite:1",
          }),
      },
    });

    const [title, options] =
      current.scope.registration.showNotification.mock.calls[0];
    expect(title).toBe("Invited");
    expect(options).toMatchObject({
      body: "Join us",
      tag: "fleet_invite:1",
      data: { url: `${ORIGIN}/fleets/invites` },
    });
  });

  it("still shows something for a push without a payload", async () => {
    await dispatch("push", { data: null });

    expect(current.scope.registration.showNotification).toHaveBeenCalledWith(
      "FleetYards",
      expect.anything(),
    );
  });
});

describe("notificationclick", () => {
  const click = (data?: Record<string, unknown>) => {
    const notification = { close: vi.fn(), data };
    return {
      notification,
      done: dispatch("notificationclick", { notification }),
    };
  };

  it("opens the link when no tab of the site is open", async () => {
    const { notification, done } = click({ url: `${ORIGIN}/hangar` });
    await done;

    expect(notification.close).toHaveBeenCalled();
    expect(current.scope.clients.openWindow).toHaveBeenCalledWith(
      `${ORIGIN}/hangar`,
    );
  });

  it("sends an open tab of the site to the link", async () => {
    const tab = {
      url: `${ORIGIN}/`,
      focus: vi.fn(),
      navigate: vi.fn().mockResolvedValue(null),
    };
    tab.focus.mockResolvedValue(tab);
    current.scope.clients.matchAll.mockResolvedValue([tab]);

    await click({ url: `${ORIGIN}/hangar` }).done;

    expect(tab.focus).toHaveBeenCalled();
    expect(tab.navigate).toHaveBeenCalledWith(`${ORIGIN}/hangar`);
  });

  // The app's own local alerts go through the same registration.
  it("leaves a local alert without a link alone", async () => {
    const { notification, done } = click(undefined);
    await done;

    expect(notification.close).toHaveBeenCalled();
    expect(current.scope.clients.matchAll).not.toHaveBeenCalled();
    expect(current.scope.clients.openWindow).not.toHaveBeenCalled();
  });
});

describe("pushsubscriptionchange", () => {
  const renewed = {
    toJSON: () => ({ endpoint: "https://fcm.googleapis.com/new", keys: {} }),
  };

  it("saves the renewed subscription", async () => {
    const fetch = vi.fn().mockResolvedValue({ ok: true, status: 201 });
    vi.stubGlobal("fetch", fetch);

    const [result] = await dispatch("pushsubscriptionchange", {
      newSubscription: renewed,
      oldSubscription: null,
    });

    expect(result.status).toBe("fulfilled");
    expect(fetch).toHaveBeenCalledWith(
      "/api/v1/push-subscriptions",
      expect.objectContaining({
        method: "POST",
        credentials: "include",
        body: JSON.stringify(renewed.toJSON()),
      }),
    );
  });

  it("re-subscribes with the old key when the browser handed over none", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({ ok: true }));
    current.scope.registration.pushManager.subscribe.mockResolvedValue(renewed);
    const applicationServerKey = new Uint8Array([4, 1, 2]);

    await dispatch("pushsubscriptionchange", {
      newSubscription: null,
      oldSubscription: { options: { applicationServerKey } },
    });

    expect(
      current.scope.registration.pushManager.subscribe,
    ).toHaveBeenCalledWith({ userVisibleOnly: true, applicationServerKey });
  });

  it("does not pass a refused save off as done", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: false, status: 401 }),
    );

    const [result] = await dispatch("pushsubscriptionchange", {
      newSubscription: renewed,
      oldSubscription: null,
    });

    expect(result.status).toBe("rejected");
  });
});
