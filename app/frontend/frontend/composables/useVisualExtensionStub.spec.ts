import { mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h } from "vue";
import {
  VISUAL_TEARDOWN_DELAY,
  signedInExtension,
  useVisualExtensionStub,
} from "./useVisualExtensionStub";
import { useSyncExtension } from "./useSyncExtension";
import { FleetyardsSyncAction } from "@/frontend/lib/FleetyardsSyncHandler";

const emit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));

const page = (handle: string) =>
  defineComponent({
    setup() {
      useVisualExtensionStub().configure(signedInExtension(handle));

      return () => h("div");
    },
  });

const identify = () =>
  useSyncExtension().request(FleetyardsSyncAction.IDENTIFY, {}, 100);

describe("useVisualExtensionStub", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    emit.mockClear();
  });

  afterEach(() => {
    vi.runAllTimers();
    vi.useRealTimers();
  });

  it("answers in code, with nothing posted on window", async () => {
    const posted = vi.spyOn(window, "postMessage");
    const wrapper = mount(page("Pilot"));

    await expect(identify()).resolves.toMatchObject({
      payload: { handle: "Pilot" },
    });
    expect(posted).not.toHaveBeenCalled();

    wrapper.unmount();
  });

  it("closes the modal on leaving, and keeps answering until it is done", async () => {
    const wrapper = mount(page("Pilot"));
    wrapper.unmount();

    expect(emit).toHaveBeenCalledWith("close-modal");
    await expect(identify()).resolves.toMatchObject({
      payload: { handle: "Pilot" },
    });

    vi.advanceTimersByTime(VISUAL_TEARDOWN_DELAY);
    const posted = vi.spyOn(window, "postMessage").mockImplementation(() => {});
    void identify().catch(() => undefined);

    expect(posted).toHaveBeenCalled();
  });

  it("leaves the next page's stub alone", async () => {
    mount(page("First")).unmount();
    const second = mount(page("Second"));

    vi.advanceTimersByTime(VISUAL_TEARDOWN_DELAY);

    await expect(identify()).resolves.toMatchObject({
      payload: { handle: "Second" },
    });

    second.unmount();
  });
});
