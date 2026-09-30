import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const createPushSubscription = vi.fn();
const destroyPushSubscription = vi.fn();

vi.mock("@/services/fyApi", () => ({
  createPushSubscription: (...args: unknown[]) =>
    createPushSubscription(...args),
  destroyPushSubscription: (...args: unknown[]) =>
    destroyPushSubscription(...args),
}));

import {
  WebPushStatusEnum,
  applicationServerKey,
  useWebPush,
} from "./useWebPush";

const KEY =
  "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM";

const browserSubscription = (endpoint = "https://fcm.googleapis.com/abc") => ({
  endpoint,
  toJSON: () => ({ endpoint, keys: { p256dh: "p", auth: "a" } }),
  input: { endpoint, expirationTime: null, keys: { p256dh: "p", auth: "a" } },
  unsubscribe: vi.fn().mockResolvedValue(true),
});

type FakeSubscription = ReturnType<typeof browserSubscription>;

const setup = ({
  permission = "default" as NotificationPermission,
  requested = "granted" as NotificationPermission,
  existing = null as FakeSubscription | null,
  registered = true,
  key = KEY as string | undefined,
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
    },
  });
  window.VAPID_PUBLIC_KEY = key;

  return { pushManager, created };
};

beforeEach(() => {
  createPushSubscription.mockResolvedValue({ id: "row-1" });
  destroyPushSubscription.mockResolvedValue(undefined);
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.clearAllMocks();
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

  it("is unsupported where no worker is registered", async () => {
    setup({ registered: false });
    const push = useWebPush();

    await push.refresh();

    expect(push.status.value).toBe(WebPushStatusEnum.UNSUPPORTED);
  });

  it("reports a permission the browser already denied", () => {
    setup({ permission: "denied" });

    expect(useWebPush().status.value).toBe(WebPushStatusEnum.DENIED);
  });

  it("is off until this browser subscribes", async () => {
    setup();
    const push = useWebPush();

    await push.refresh();

    expect(push.status.value).toBe(WebPushStatusEnum.OFF);
    expect(createPushSubscription).not.toHaveBeenCalled();
  });

  // Every visit re-announces the browser, which is how the page learns which
  // of the account's devices is this one.
  it("re-announces a browser that subscribed on an earlier visit", async () => {
    const existing = browserSubscription();
    setup({ permission: "granted", existing });
    const push = useWebPush();

    await push.refresh();

    expect(createPushSubscription).toHaveBeenCalledWith(existing.input);
    expect(push.subscriptionId.value).toBe("row-1");
    expect(push.status.value).toBe(WebPushStatusEnum.ON);
  });

  it("subscribes with the server key once permission is granted", async () => {
    const { pushManager, created } = setup();
    const push = useWebPush();

    expect(await push.enable()).toBe(true);

    const [{ userVisibleOnly, applicationServerKey: key }] =
      pushManager.subscribe.mock.calls[0];
    expect(userVisibleOnly).toBe(true);
    expect(key).toEqual(applicationServerKey(KEY));
    expect(createPushSubscription).toHaveBeenCalledWith(created.input);
    expect(push.status.value).toBe(WebPushStatusEnum.ON);
  });

  it("subscribes nothing when the reader declines the prompt", async () => {
    const { pushManager } = setup({ requested: "denied" });
    const push = useWebPush();

    expect(await push.enable()).toBe(false);

    expect(pushManager.subscribe).not.toHaveBeenCalled();
    expect(push.status.value).toBe(WebPushStatusEnum.DENIED);
  });

  it("turning off removes the server's row and the browser's subscription", async () => {
    const existing = browserSubscription();
    setup({ permission: "granted", existing });
    const push = useWebPush();
    await push.refresh();

    await push.disable();

    expect(destroyPushSubscription).toHaveBeenCalledWith("row-1");
    expect(existing.unsubscribe).toHaveBeenCalled();
    expect(push.status.value).toBe(WebPushStatusEnum.OFF);
  });
});
