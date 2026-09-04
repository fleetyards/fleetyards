import { flushPromises, mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, ref, type Ref } from "vue";
import {
  usePullToRefresh,
  PULL_LIMIT_PX,
  PULL_THRESHOLD_PX,
} from "./usePullToRefresh";
import { MINIMUM_WAIT_MS } from "./useMinimumDuration";

beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();
});

// The pull is damped, so the finger covers twice what the indicator does.
const fingerTravelFor = (indicatorTravel: number) => indicatorTravel * 2;

/*
 * jsdom ships no TouchEvent, and the composable only ever reads `touches`,
 * `target` and `cancelable` off the event - so the event carries just those.
 */
const touch = (type: string, clientY?: number) => {
  const event = new Event(type, { bubbles: true, cancelable: true });

  if (clientY !== undefined) {
    Object.defineProperty(event, "touches", { value: [{ clientY }] });
  } else {
    Object.defineProperty(event, "touches", { value: [] });
  }

  return event;
};

type RenderOptions = {
  refresh?: () => Promise<unknown> | unknown;
  disabled?: Ref<boolean>;
};

const render = async ({
  refresh = () => undefined,
  disabled,
}: RenderOptions) => {
  const state = { distance: 0, armed: false, refreshing: false };

  // A component, because the composable hangs its listeners and its clean-up
  // off the surrounding scope.
  const wrapper = mount(
    defineComponent({
      setup() {
        const root = ref<HTMLElement | null>(null);

        const pull = usePullToRefresh({ target: root, refresh, disabled });

        return () => {
          state.distance = pull.distance.value;
          state.armed = pull.armed.value;
          state.refreshing = pull.refreshing.value;

          return h("div", { ref: root }, [
            h("div", { class: "content" }),
            h("canvas"),
          ]);
        };
      },
    }),
    { attachTo: document.body },
  );

  await flushPromises();

  const root = wrapper.element as HTMLElement;

  return {
    wrapper,
    state,
    root,
    content: root.querySelector(".content") as HTMLElement,
    canvas: root.querySelector("canvas") as HTMLElement,
  };
};

const advance = async (ms: number) => {
  vi.advanceTimersByTime(ms);

  await flushPromises();
};

const pull = async (from: HTMLElement, indicatorTravel: number) => {
  from.dispatchEvent(touch("touchstart", 0));
  from.dispatchEvent(touch("touchmove", fingerTravelFor(indicatorTravel)));

  await flushPromises();
};

describe("usePullToRefresh", () => {
  it("follows the finger at half speed, up to the limit", async () => {
    const { state, root } = await render({});

    await pull(root, 20);

    expect(state.distance).toBe(20);
    expect(state.armed).toBe(false);

    root.dispatchEvent(
      touch("touchmove", fingerTravelFor(PULL_LIMIT_PX + 200)),
    );

    await flushPromises();

    expect(state.distance).toBe(PULL_LIMIT_PX);
  });

  it("refreshes when a pull past the threshold is released", async () => {
    const refresh = vi.fn().mockResolvedValue(undefined);
    const { state, root } = await render({ refresh });

    await pull(root, PULL_THRESHOLD_PX);

    expect(state.armed).toBe(true);

    root.dispatchEvent(touch("touchend"));

    await flushPromises();

    expect(refresh).toHaveBeenCalledOnce();
    expect(state.refreshing).toBe(true);
    // Parked at the threshold rather than where the finger stopped.
    expect(state.distance).toBe(PULL_THRESHOLD_PX);

    await advance(MINIMUM_WAIT_MS);

    expect(state.refreshing).toBe(false);
    expect(state.distance).toBe(0);
  });

  it("holds the indicator up for an answer that arrives too fast to be seen", async () => {
    const refresh = vi.fn().mockResolvedValue(undefined);
    const { state, root } = await render({ refresh });

    await pull(root, PULL_THRESHOLD_PX);

    root.dispatchEvent(touch("touchend"));

    await advance(MINIMUM_WAIT_MS - 100);

    expect(state.refreshing).toBe(true);

    await advance(100);

    expect(state.refreshing).toBe(false);
  });

  it("stops on a refresh that fails", async () => {
    const refresh = vi.fn().mockRejectedValue(new Error("nope"));
    const { state, root } = await render({ refresh });

    await pull(root, PULL_THRESHOLD_PX);

    root.dispatchEvent(touch("touchend"));

    await advance(MINIMUM_WAIT_MS);

    expect(state.refreshing).toBe(false);
    expect(state.distance).toBe(0);
  });

  it("does not refresh a pull released short of the threshold", async () => {
    const refresh = vi.fn();
    const { state, root } = await render({ refresh });

    await pull(root, PULL_THRESHOLD_PX - 10);

    root.dispatchEvent(touch("touchend"));

    await flushPromises();

    expect(refresh).not.toHaveBeenCalled();
    expect(state.distance).toBe(0);
  });

  it("hands the gesture back once the finger turns upwards", async () => {
    const refresh = vi.fn();
    const { state, root } = await render({ refresh });

    await pull(root, PULL_THRESHOLD_PX);

    root.dispatchEvent(touch("touchmove", -10));

    await flushPromises();

    expect(state.distance).toBe(0);

    // Back past the threshold without a fresh touchstart: the gesture is over.
    root.dispatchEvent(touch("touchmove", fingerTravelFor(PULL_THRESHOLD_PX)));
    root.dispatchEvent(touch("touchend"));

    await flushPromises();

    expect(refresh).not.toHaveBeenCalled();
    expect(state.distance).toBe(0);
  });

  it("keeps its hands off a pull that belongs to an inner scroller", async () => {
    const refresh = vi.fn();
    const { state, content } = await render({ refresh });

    // jsdom has no layout, so the scroll position has to be declared.
    Object.defineProperty(content, "scrollTop", { value: 40 });

    await pull(content, PULL_THRESHOLD_PX);

    content.dispatchEvent(touch("touchend"));

    await flushPromises();

    expect(state.distance).toBe(0);
    expect(refresh).not.toHaveBeenCalled();
  });

  it("keeps its hands off a canvas, which reads the drag itself", async () => {
    const refresh = vi.fn();
    const { state, canvas } = await render({ refresh });

    await pull(canvas, PULL_THRESHOLD_PX);

    canvas.dispatchEvent(touch("touchend"));

    await flushPromises();

    expect(state.distance).toBe(0);
    expect(refresh).not.toHaveBeenCalled();
  });

  it("does nothing while a drawer or a modal has the screen", async () => {
    const refresh = vi.fn();
    const disabled = ref(true);
    const { state, root } = await render({ refresh, disabled });

    await pull(root, PULL_THRESHOLD_PX);

    root.dispatchEvent(touch("touchend"));

    await flushPromises();

    expect(state.distance).toBe(0);
    expect(refresh).not.toHaveBeenCalled();

    disabled.value = false;

    await flushPromises();
    await pull(root, PULL_THRESHOLD_PX);

    root.dispatchEvent(touch("touchend"));

    await flushPromises();

    expect(refresh).toHaveBeenCalledOnce();
  });

  it("keeps the page from scrolling under a pull it has taken over", async () => {
    const { root } = await render({});

    root.dispatchEvent(touch("touchstart", 0));

    const move = touch("touchmove", fingerTravelFor(20));
    const prevented = vi.spyOn(move, "preventDefault");

    root.dispatchEvent(move);

    await flushPromises();

    expect(prevented).toHaveBeenCalled();
  });

  it("leaves a downward scroll to the page", async () => {
    const { root } = await render({});

    root.dispatchEvent(touch("touchstart", 0));

    const move = touch("touchmove", -20);
    const prevented = vi.spyOn(move, "preventDefault");

    root.dispatchEvent(move);

    await flushPromises();

    expect(prevented).not.toHaveBeenCalled();
  });
});
