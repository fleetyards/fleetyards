import { beforeEach, describe, expect, it, vi } from "vitest";
import { nextTick } from "vue";

type Location = { path: string };
type Hook = (to: Location, from: Location, failure?: unknown) => void;

const START_LOCATION: Location = { path: "/" };

const hooks: Hook[] = [];

const trackView = vi.fn();

let installed = false;

vi.mock("vue-router", () => ({
  START_LOCATION,
  useRouter: () => ({ afterEach: (hook: Hook) => hooks.push(hook) }),
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

  it("tracks the page the app was loaded on", () => {
    useAhoy();

    expect(trackView).toHaveBeenCalledExactlyOnceWith({});
  });

  it("does not count the initial navigation twice", async () => {
    useAhoy();
    await navigate("/hangar/", START_LOCATION);

    expect(trackView).toHaveBeenCalledOnce();
  });

  it("tracks every navigation to another page", async () => {
    useAhoy();
    await navigate("/hangar/", "/");
    await navigate("/fleets/", "/hangar/");

    expect(trackView).toHaveBeenCalledTimes(3);
  });

  it("ignores a change that stays on the same page", async () => {
    useAhoy();
    await navigate("/hangar/", "/hangar/");

    expect(trackView).toHaveBeenCalledOnce();
  });

  it("ignores a navigation that failed", async () => {
    useAhoy();
    hooks.forEach((hook) =>
      hook({ path: "/fleets/" }, { path: "/hangar/" }, new Error("aborted")),
    );
    await nextTick();

    expect(trackView).toHaveBeenCalledOnce();
  });

  it("marks every view from the installed app", async () => {
    installed = true;
    useAhoy();
    await navigate("/hangar/", "/");

    expect(trackView).toHaveBeenNthCalledWith(1, { installed: true });
    expect(trackView).toHaveBeenNthCalledWith(2, { installed: true });
  });
});
