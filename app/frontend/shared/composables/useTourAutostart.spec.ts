import { mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, nextTick, ref } from "vue";
import { useTourAutostart } from "./useTourAutostart";

const ready = ref(false);
const start = vi.fn();

const Host = defineComponent({
  setup() {
    useTourAutostart({ ready, start, delay: 800 });
    return () => null;
  },
});

beforeEach(() => {
  vi.useFakeTimers();
  ready.value = false;
  start.mockReset();
});

afterEach(() => {
  vi.useRealTimers();
});

describe("useTourAutostart", () => {
  it("starts once the page has been ready for the delay", async () => {
    mount(Host);

    ready.value = true;
    await nextTick();
    vi.advanceTimersByTime(799);
    expect(start).not.toHaveBeenCalled();

    vi.advanceTimersByTime(1);
    expect(start).toHaveBeenCalledTimes(1);
  });

  it("drops the start when the user acts first", async () => {
    mount(Host);

    ready.value = true;
    await nextTick();
    document.dispatchEvent(new Event("pointerdown"));
    vi.advanceTimersByTime(1000);

    expect(start).not.toHaveBeenCalled();
  });

  it("starts at most once per visit, however often it turns ready", async () => {
    mount(Host);

    ready.value = true;
    await nextTick();
    vi.advanceTimersByTime(800);

    ready.value = false;
    await nextTick();
    ready.value = true;
    await nextTick();
    vi.advanceTimersByTime(800);

    expect(start).toHaveBeenCalledTimes(1);
  });

  it("does nothing once the page is gone", async () => {
    const wrapper = mount(Host);

    ready.value = true;
    await nextTick();
    wrapper.unmount();
    vi.advanceTimersByTime(1000);

    expect(start).not.toHaveBeenCalled();
  });
});
