import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const createPushSubscription = vi.fn();
const destroyPushSubscription = vi.fn();
const touchPushSubscription = vi.fn();

vi.mock("@/services/fyApi", () => ({
  createPushSubscription: (...args: unknown[]) =>
    createPushSubscription(...args),
  destroyPushSubscription: (...args: unknown[]) =>
    destroyPushSubscription(...args),
  touchPushSubscription: (...args: unknown[]) => touchPushSubscription(...args),
}));

import {
  WebPushStatusEnum,
  applicationServerKey,
  useWebPush,
} from "./useWebPush";

const KEY =
  "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM";
const USER = "user-1";
const STORAGE_KEY = "fy.push-subscription";

const browserSubscription = (endpoint = "https://fcm.googleapis.com/abc") => ({
  endpoint,
  toJSON: () => ({ endpoint, keys: { p256dh: "p", auth: "a" } }),
  input: { endpoint, expirationTime: null, keys: { p256dh: "p", auth: "a" } },
  unsubscribe: vi.fn().mockResolvedValue(true),
});

type FakeSubscription = ReturnType<typeof browserSubscription>;

const remember = (
  id: string,
  endpoint: string,
  userId = USER,
  keys = { p256dh: "p", auth: "a" },
) =>
  localStorage.setItem(
    STORAGE_KEY,
    JSON.stringify({ id, endpoint, userId, ...keys }),
  );

const stored = () => JSON.parse(localStorage.getItem(STORAGE_KEY) ?? "null");

const setup = ({
  permission = "default" as NotificationPermission,
  requested = "granted" as NotificationPermission,
  existing = null as FakeSubscription | null,
  registered = true,
  ready = new Promise<unknown>(() => {}),
  key = KEY,
} = {}) => {
  const created = browserSubscription();
  const pushManager = {
    getSubscription: vi.fn().mockResolvedValue(existing),
    subscribe: vi.fn().mockResolvedValue(created),
  };

  vi.stubGlobal("PushManager", class {});
  vi.stubGlobal("Notification", {
    permission,
    requestPermission: vi.fn().mockResolvedValue(requested),
  });
  Object.defineProperty(navigator, "serviceWorker", {
    configurable: true,
    value: {
      getRegistration: vi
        .fn()
        .mockResolvedValue(registered ? { pushManager } : undefined),
      ready: registered ? Promise.resolve({ pushManager }) : ready,
    },
  });
  window.VAPID_PUBLIC_KEY = key;

  return { pushManager, created };
};

beforeEach(() => {
  createPushSubscription.mockResolvedValue({ id: "row-1" });
  destroyPushSubscription.mockResolvedValue(undefined);
  touchPushSubscription.mockResolvedValue({ id: "row-1" });
});

afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
  vi.clearAllMocks();
  localStorage.clear();
  window.VAPID_PUBLIC_KEY = undefined;
});

describe("applicationServerKey", () => {
  it("decodes the base64url key to its raw 65 bytes", () => {
    const bytes = applicationServerKey(KEY);

    expect(bytes).toHaveLength(65);
    expect(bytes[0]).toBe(4);
  });
});

describe("useWebPush", () => {
  it("is unsupported without a server key", () => {
    setup({ key: "" });

    expect(useWebPush().status.value).toBe(WebPushStatusEnum.UNSUPPORTED);
  });

  it("reports a permission the browser already denied", () => {
    setup({ permission: "denied" });

    expect(useWebPush().status.value).toBe(WebPushStatusEnum.DENIED);
  });

  // Registration runs after DOMContentLoaded; a page opened straight away
  // can ask first.
  it("waits for a worker that is still registering", async () => {
    let register: (value: unknown) => void = () => {};
    const ready = new Promise((resolve) => {
      register = resolve;
    });
    const { pushManager } = setup({ registered: false, ready });
    const push = useWebPush();

    const refreshing = push.refresh(USER);
    register({ pushManager });
    await refreshing;

    expect(push.status.value).toBe(WebPushStatusEnum.OFF);
  });

  // A slow worker is not proof the subscription is gone.
  it("is unsupported once no worker shows up, and keeps what it knew", async () => {
    vi.useFakeTimers();
    remember("row-1", "https://fcm.googleapis.com/abc");
    setup({ registered: false });
    const push = useWebPush();

    const refreshing = push.refresh(USER);
    await vi.advanceTimersByTimeAsync(10_000);
    await refreshing;

    expect(push.status.value).toBe(WebPushStatusEnum.UNSUPPORTED);
    expect(stored()).toEqual({
      id: "row-1",
      endpoint: "https://fcm.googleapis.com/abc",
      userId: USER,
      p256dh: "p",
      auth: "a",
    });
  });

  it("is off until this browser subscribes", async () => {
    setup();
    const push = useWebPush();

    await push.refresh(USER);

    expect(push.status.value).toBe(WebPushStatusEnum.OFF);
    expect(createPushSubscription).not.toHaveBeenCalled();
  });

  // The touch is the server's sign that the device is still in use; it never
  // recreates a row, and it leaves the failure count alone.
  it("is on, and touches the row, while the server still has it", async () => {
    const existing = browserSubscription();
    remember("row-1", existing.endpoint);
    setup({ permission: "granted", existing });
    const push = useWebPush();

    await push.refresh(USER);

    expect(push.status.value).toBe(WebPushStatusEnum.ON);
    expect(push.subscriptionId.value).toBe("row-1");
    expect(touchPushSubscription).toHaveBeenCalledWith("row-1");
    expect(createPushSubscription).not.toHaveBeenCalled();
  });

  // The worker saves a renewal itself, but it has no session once the reader
  // is logged out.
  it("saves a renewal the server never heard about", async () => {
    const existing = browserSubscription("https://fcm.googleapis.com/renewed");
    remember("row-0", "https://fcm.googleapis.com/old");
    setup({ permission: "granted", existing });
    const push = useWebPush();

    await push.refresh(USER);

    expect(createPushSubscription).toHaveBeenCalledWith({
      ...existing.input,
      replaces: "row-0",
    });
    expect(stored()).toEqual({
      id: "row-1",
      endpoint: existing.endpoint,
      userId: USER,
      p256dh: "p",
      auth: "a",
    });
    expect(push.status.value).toBe(WebPushStatusEnum.ON);
  });

  it("saves keys the browser renewed on the same endpoint", async () => {
    const existing = browserSubscription();
    remember("row-1", existing.endpoint, USER, { p256dh: "old", auth: "a" });
    setup({ permission: "granted", existing });
    const push = useWebPush();

    await push.refresh(USER);

    expect(touchPushSubscription).toHaveBeenCalledWith("row-1");
    expect(createPushSubscription).toHaveBeenCalledWith(existing.input);
    expect(stored().p256dh).toBe("p");
  });

  it("does not bring back a removed device when it renews", async () => {
    const existing = browserSubscription("https://fcm.googleapis.com/renewed");
    remember("row-0", "https://fcm.googleapis.com/old");
    touchPushSubscription.mockRejectedValue({
      isAxiosError: true,
      response: { status: 404 },
    });
    setup({ permission: "granted", existing });
    const push = useWebPush();

    await push.refresh(USER);

    expect(createPushSubscription).not.toHaveBeenCalled();
    expect(existing.unsubscribe).toHaveBeenCalled();
    expect(stored()).toBeNull();
    expect(push.status.value).toBe(WebPushStatusEnum.OFF);
  });

  it("stays off for a device this account removed elsewhere", async () => {
    const existing = browserSubscription();
    remember("row-1", existing.endpoint);
    touchPushSubscription.mockRejectedValue({
      isAxiosError: true,
      response: { status: 404 },
    });
    setup({ permission: "granted", existing });
    const push = useWebPush();

    await push.refresh(USER);

    expect(createPushSubscription).not.toHaveBeenCalled();
    expect(existing.unsubscribe).toHaveBeenCalled();
    expect(stored()).toBeNull();
    expect(push.status.value).toBe(WebPushStatusEnum.OFF);
  });

  it("leaves another account's subscription alone", async () => {
    const existing = browserSubscription();
    remember("row-1", existing.endpoint, "someone-else");
    setup({ permission: "granted", existing });
    const push = useWebPush();

    await push.refresh(USER);

    expect(createPushSubscription).not.toHaveBeenCalled();
    expect(existing.unsubscribe).not.toHaveBeenCalled();
    expect(push.status.value).toBe(WebPushStatusEnum.OFF);
  });

  it("reports a check that failed instead of reading as off", async () => {
    const existing = browserSubscription();
    remember("row-1", existing.endpoint);
    touchPushSubscription.mockRejectedValue({
      isAxiosError: true,
      response: { status: 503 },
    });
    setup({ permission: "granted", existing });
    const push = useWebPush();

    await expect(push.refresh(USER)).rejects.toThrow();

    expect(push.status.value).toBe(WebPushStatusEnum.FAILED);
  });

  it("subscribes with the server key once permission is granted", async () => {
    const { pushManager, created } = setup();
    const push = useWebPush();

    expect(await push.enable(USER)).toBe(true);

    const [{ userVisibleOnly, applicationServerKey: key }] =
      pushManager.subscribe.mock.calls[0];
    expect(userVisibleOnly).toBe(true);
    expect(key).toEqual(applicationServerKey(KEY));
    expect(createPushSubscription).toHaveBeenCalledWith(created.input);
    expect(stored()).toEqual({
      id: "row-1",
      endpoint: created.endpoint,
      userId: USER,
      p256dh: "p",
      auth: "a",
    });
    expect(push.status.value).toBe(WebPushStatusEnum.ON);
  });

  it("subscribes nothing when the reader declines the prompt", async () => {
    const { pushManager } = setup({ requested: "denied" });
    const push = useWebPush();

    expect(await push.enable(USER)).toBe(false);

    expect(pushManager.subscribe).not.toHaveBeenCalled();
    expect(push.status.value).toBe(WebPushStatusEnum.DENIED);
  });

  it("turning off unsubscribes the browser, then removes the server's row", async () => {
    const existing = browserSubscription();
    remember("row-1", existing.endpoint);
    setup({ permission: "granted", existing });
    const push = useWebPush();
    await push.refresh(USER);

    await push.disable();

    expect(existing.unsubscribe).toHaveBeenCalled();
    expect(destroyPushSubscription).toHaveBeenCalledWith("row-1");
    expect(stored()).toBeNull();
    expect(push.status.value).toBe(WebPushStatusEnum.OFF);
  });

  it("stays on when the browser refuses to unsubscribe", async () => {
    const existing = browserSubscription();
    existing.unsubscribe.mockResolvedValue(false);
    remember("row-1", existing.endpoint);
    setup({ permission: "granted", existing });
    const push = useWebPush();
    await push.refresh(USER);

    await expect(push.disable()).rejects.toThrow();

    expect(destroyPushSubscription).not.toHaveBeenCalled();
    expect(push.status.value).toBe(WebPushStatusEnum.ON);
  });
});
