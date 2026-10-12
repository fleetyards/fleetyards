import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { LONG_PRESS_MS, useLongPress } from "./useLongPress";

const haptics = vi.hoisted(() => ({
  tick: vi.fn(),
}));

vi.mock("@/shared/utils/Haptics", () => ({
  hapticTick: haptics.tick,
}));

beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();
  haptics.tick.mockReset();
});

const touch = (type: string, clientX?: number, clientY = 0, fingers = 1) => {
  const event = new Event(type, { bubbles: true, cancelable: true });

  Object.defineProperty(event, "touches", {
    value:
      clientX === undefined
        ? []
        : Array.from({ length: fingers }, () => ({ clientX, clientY })),
  });

  return event;
};

const render = async () => {
  const onLongPress = vi.fn();
  const clicks = vi.fn();

  const wrapper = mount(
    defineComponent({
      setup() {
        const row = ref<HTMLElement>();

        useLongPress({ target: row, onLongPress });

        return () => h("div", { ref: row, class: "row", onClick: clicks });
      },
    }),
    { attachTo: document.body },
  );

  await flushPromises();

  const row = wrapper.element as HTMLElement;

  return { wrapper, row, onLongPress, clicks };
};

describe("useLongPress", () => {
  it("fires once the finger has rested for the hold time", async () => {
    const { row, onLongPress } = await render();

    row.dispatchEvent(touch("touchstart", 100, 100));
    vi.advanceTimersByTime(LONG_PRESS_MS - 1);

    expect(onLongPress).not.toHaveBeenCalled();

    vi.advanceTimersByTime(1);

    expect(onLongPress).toHaveBeenCalledTimes(1);
  });

  it("does not fire for a tap", async () => {
    const { row, onLongPress } = await render();

    row.dispatchEvent(touch("touchstart", 100, 100));
    vi.advanceTimersByTime(100);
    row.dispatchEvent(touch("touchend"));
    vi.advanceTimersByTime(LONG_PRESS_MS);

    expect(onLongPress).not.toHaveBeenCalled();
  });

  it("gives way to a finger that moves off into a scroll or a swipe", async () => {
    const { row, onLongPress } = await render();

    row.dispatchEvent(touch("touchstart", 100, 100));
    row.dispatchEvent(touch("touchmove", 100, 130));
    vi.advanceTimersByTime(LONG_PRESS_MS);

    expect(onLongPress).not.toHaveBeenCalled();
  });

  it("tolerates the drift of a resting finger", async () => {
    const { row, onLongPress } = await render();

    row.dispatchEvent(touch("touchstart", 100, 100));
    row.dispatchEvent(touch("touchmove", 104, 103));
    vi.advanceTimersByTime(LONG_PRESS_MS);

    expect(onLongPress).toHaveBeenCalledTimes(1);
  });

  it("gives way to a second finger landing outside the row", async () => {
    const { row, onLongPress } = await render();

    row.dispatchEvent(touch("touchstart", 100, 100));
    document.body.dispatchEvent(touch("touchstart", 300, 300, 2));
    vi.advanceTimersByTime(LONG_PRESS_MS);

    expect(onLongPress).not.toHaveBeenCalled();
  });

  it("gives way when a move reports a second finger", async () => {
    const { row, onLongPress } = await render();

    row.dispatchEvent(touch("touchstart", 100, 100));
    row.dispatchEvent(touch("touchmove", 100, 100, 2));
    vi.advanceTimersByTime(LONG_PRESS_MS);

    expect(onLongPress).not.toHaveBeenCalled();
  });

  it("swallows the click that follows the hold, not a later tap", async () => {
    const { row, clicks } = await render();

    row.dispatchEvent(touch("touchstart", 100, 100));
    vi.advanceTimersByTime(LONG_PRESS_MS);
    row.dispatchEvent(touch("touchend"));
    row.click();

    expect(clicks).not.toHaveBeenCalled();

    row.dispatchEvent(touch("touchstart", 100, 100));
    row.dispatchEvent(touch("touchend"));
    row.click();

    expect(clicks).toHaveBeenCalledTimes(1);
  });

  it("keeps the context menu from opening over a hold", async () => {
    const { row } = await render();

    row.dispatchEvent(touch("touchstart", 100, 100));
    vi.advanceTimersByTime(LONG_PRESS_MS);

    const menu = new Event("contextmenu", { cancelable: true });
    row.dispatchEvent(menu);

    expect(menu.defaultPrevented).toBe(true);
  });

  it("ticks when the hold lands", async () => {
    const { row } = await render();

    row.dispatchEvent(touch("touchstart", 100, 100));
    vi.advanceTimersByTime(LONG_PRESS_MS);

    expect(haptics.tick).toHaveBeenCalledTimes(1);
  });
});
