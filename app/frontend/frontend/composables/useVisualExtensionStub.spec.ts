import { mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  signedInExtension,
  useVisualExtensionStub,
} from "./useVisualExtensionStub";
import { useSyncExtension } from "./useSyncExtension";
import { FleetyardsSyncAction } from "@/frontend/lib/FleetyardsSyncHandler";

const emit = vi.fn();
const handlers = new Map<string, Set<() => void>>();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({
    emit,
    on: (event: string, handler: () => void) => {
      const set = handlers.get(event) ?? new Set();
      set.add(handler);
      handlers.set(event, set);

      return () => set.delete(handler);
    },
  }),
}));

const modalClosed = () =>
  [...(handlers.get("modal-closed") ?? [])].forEach((handler) => handler());

const page = (handle: string) =>
  defineComponent({
    setup() {
      useVisualExtensionStub().configure(signedInExtension(handle));

      return () => h("div");
    },
  });

const identify = () =>
  useSyncExtension().request(FleetyardsSyncAction.IDENTIFY, {}, 100);

// Whether a request goes past the stub to `window`, where a real extension
// would hear it.
const reachesWindow = () => {
  const posted = vi.spyOn(window, "postMessage").mockImplementation(() => {});
  void identify().catch(() => undefined);

  return posted.mock.calls.length > 0;
};

describe("useVisualExtensionStub", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    emit.mockClear();
    handlers.clear();
  });

  afterEach(() => {
    vi.runAllTimers();
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it("answers in code, with nothing posted on window", async () => {
    const wrapper = mount(page("Pilot"));

    expect(reachesWindow()).toBe(false);
    await expect(identify()).resolves.toMatchObject({
      payload: { handle: "Pilot" },
    });

    wrapper.unmount();
  });

  it("force-closes the modal on leaving, and tears down once it is gone", () => {
    mount(page("Pilot")).unmount();

    expect(emit).toHaveBeenCalledWith("close-modal", true);
    expect(reachesWindow()).toBe(false);

    modalClosed();

    expect(reachesWindow()).toBe(true);
  });

  it("tears down after a short wait when the modal never reports back", () => {
    mount(page("Pilot")).unmount();

    vi.advanceTimersByTime(1000);

    expect(reachesWindow()).toBe(true);
  });

  it("leaves the next page's stub alone", async () => {
    mount(page("First")).unmount();
    const second = mount(page("Second"));

    modalClosed();

    await expect(identify()).resolves.toMatchObject({
      payload: { handle: "Second" },
    });

    second.unmount();
  });
});
