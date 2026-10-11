import { afterEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import {
  SWIPE_LIMIT_PX,
  SWIPE_THRESHOLD_PX,
  type SwipeDirection,
  useSwipeActions,
} from "./useSwipeActions";

afterEach(() => {
  vi.useRealTimers();
});

/*
 * jsdom ships no TouchEvent, and the composable only ever reads `touches` and
 * `cancelable` off the event - so the event carries just those.
 */
const touch = (type: string, clientX?: number, clientY = 0) => {
  const event = new Event(type, { bubbles: true, cancelable: true });

  Object.defineProperty(event, "touches", {
    value: clientX === undefined ? [] : [{ clientX, clientY }],
  });

  return event;
};

const render = async () => {
  const state = { offset: 0, armed: false };
  const swipes: SwipeDirection[] = [];
  const parentMoves = vi.fn();
  const clicks = vi.fn();

  // A component, because the composable hangs its listeners and its clean-up
  // off the surrounding scope.
  const wrapper = mount(
    defineComponent({
      setup() {
        const row = ref<HTMLElement>();

        const swipe = useSwipeActions({
          target: row,
          onSwipe: (direction) => swipes.push(direction),
        });

        return () => {
          state.offset = swipe.offset.value;
          state.armed = swipe.armed.value;

          return h("div", { onTouchmove: parentMoves }, [
            h("div", { ref: row, class: "row", onClick: clicks }),
          ]);
        };
      },
    }),
    { attachTo: document.body },
  );

  await flushPromises();

  const row = wrapper.element.querySelector(".row") as HTMLElement;

  const drag = async (dx: number, dy = 0) => {
    row.dispatchEvent(touch("touchstart", 100, 100));
    row.dispatchEvent(touch("touchmove", 100 + dx, 100 + dy));

    await flushPromises();
  };

  const release = async () => {
    row.dispatchEvent(touch("touchend"));

    await flushPromises();
  };

  return { wrapper, state, swipes, parentMoves, clicks, row, drag, release };
};

describe("useSwipeActions", () => {
  it("follows the finger, then slows past the threshold up to the limit", async () => {
    const { state, drag, row } = await render();

    await drag(40);

    expect(state.offset).toBe(40);
    expect(state.armed).toBe(false);

    row.dispatchEvent(touch("touchmove", 100 + SWIPE_THRESHOLD_PX + 1000));
    await flushPromises();

    expect(state.offset).toBe(SWIPE_LIMIT_PX);
    expect(state.armed).toBe(true);
  });

  it("acts on a swipe let go past the threshold, in its direction", async () => {
    const { swipes, drag, release } = await render();

    await drag(SWIPE_THRESHOLD_PX + 20);
    await release();
    await drag(-(SWIPE_THRESHOLD_PX + 20));
    await release();

    expect(swipes).toEqual(["right", "left"]);
  });

  it("springs back without acting on a short swipe", async () => {
    const { state, swipes, drag, release } = await render();

    await drag(SWIPE_THRESHOLD_PX - 10);
    await release();

    expect(swipes).toEqual([]);
    expect(state.offset).toBe(0);
  });

  it("leaves a mostly vertical gesture to the page", async () => {
    const { state, swipes, parentMoves, drag, release } = await render();

    await drag(30, 60);
    await release();

    expect(state.offset).toBe(0);
    expect(swipes).toEqual([]);
    expect(parentMoves).toHaveBeenCalled();
  });

  it("keeps a swipe from reaching a pull-to-refresh above it", async () => {
    const { parentMoves, drag } = await render();

    await drag(SWIPE_THRESHOLD_PX, 5);

    expect(parentMoves).not.toHaveBeenCalled();
  });

  it("swallows the click that follows a swipe, but not a later tap", async () => {
    vi.useFakeTimers();

    const { clicks, row, drag, release } = await render();

    await drag(SWIPE_THRESHOLD_PX + 20);
    await release();
    row.click();

    expect(clicks).not.toHaveBeenCalled();

    vi.advanceTimersByTime(1000);
    row.click();

    expect(clicks).toHaveBeenCalledOnce();
  });

  it("lets a new tap through right after a short nudge", async () => {
    vi.useFakeTimers();

    const { clicks, row, drag, release } = await render();

    await drag(20);
    await release();
    row.dispatchEvent(touch("touchstart", 100, 100));
    row.dispatchEvent(touch("touchend"));
    row.click();

    expect(clicks).toHaveBeenCalledOnce();
  });
});
