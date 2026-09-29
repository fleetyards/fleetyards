import { beforeEach, describe, expect, it, vi } from "vitest";
import { nextTick } from "vue";

type Location = { path: string };
type Hook = (to: Location, from: Location, failure?: unknown) => void;

const START_LOCATION: Location = { path: "/" };

const hooks: Hook[] = [];

let settle: { resolve: () => void; reject: (error: Error) => void };

const isReady = () =>
  new Promise<void>((resolve, reject) => {
    settle = { resolve, reject };
  });

const trackView = vi.fn();

let installed = false;

vi.mock("vue-router", () => ({
  START_LOCATION,
  useRouter: () => ({
    afterEach: (hook: Hook) => hooks.push(hook),
    isReady,
  }),
}));

vi.mock("ahoy.js", () => ({
  default: {
    configure: vi.fn(),
    track: vi.fn(),
    trackView,
    trackSubmits: vi.fn(),
  },
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({ authenticated: false }),
}));

vi.mock("@/frontend/stores/cookies", () => ({
  useCookiesStore: () => ({ trackingAccepted: true }),
}));

vi.mock("@/shared/utils/DisplayMode", () => ({
  isInstalledApp: () => installed,
}));

const { useAhoy } = await import("./useAhoy");

const flush = () => new Promise((resolve) => setTimeout(resolve));

const load = async () => {
  useAhoy();
  settle.resolve();
  await flush();
};

const navigate = async (to: string, from: Location | string) => {
  hooks.forEach((hook) =>
    hook({ path: to }, typeof from === "string" ? { path: from } : from),
  );
  await nextTick();
};

describe("useAhoy", () => {
  beforeEach(() => {
    hooks.splice(0);
    trackView.mockClear();
    installed = false;
  });

  it("tracks the page the app was loaded on once its navigation settles", async () => {
    useAhoy();
    await flush();

    expect(trackView).not.toHaveBeenCalled();

    settle.resolve();
    await flush();

    expect(trackView).toHaveBeenCalledExactlyOnceWith({});
  });

  it("tracks a load whose initial navigation failed", async () => {
    useAhoy();
    settle.reject(new Error("guard threw"));
    await flush();

    expect(trackView).toHaveBeenCalledOnce();
  });

  it("does not count the initial navigation twice", async () => {
    await load();
    await navigate("/hangar/", START_LOCATION);

    expect(trackView).toHaveBeenCalledOnce();
  });

  it("tracks every navigation to another page", async () => {
    await load();
    await navigate("/hangar/", "/");
    await navigate("/fleets/", "/hangar/");

    expect(trackView).toHaveBeenCalledTimes(3);
  });

  it("ignores a change that stays on the same page", async () => {
    await load();
    await navigate("/hangar/", "/hangar/");

    expect(trackView).toHaveBeenCalledOnce();
  });

  it("ignores a trailing slash added to the same page", async () => {
    await load();
    await navigate("/compare/", "/compare");

    expect(trackView).toHaveBeenCalledOnce();
  });

  it("ignores a navigation that failed", async () => {
    await load();
    hooks.forEach((hook) =>
      hook({ path: "/fleets/" }, { path: "/hangar/" }, new Error("aborted")),
    );
    await nextTick();

    expect(trackView).toHaveBeenCalledOnce();
  });

  it("marks every view from the installed app", async () => {
    installed = true;
    await load();
    await navigate("/hangar/", "/");

    expect(trackView).toHaveBeenNthCalledWith(1, { installed: true });
    expect(trackView).toHaveBeenNthCalledWith(2, { installed: true });
  });
});
