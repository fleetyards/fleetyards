import { describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import {
  type SwipeToDismissSide,
  useSwipeToDismiss,
} from "./useSwipeToDismiss";

const PANEL_WIDTH = 200;

/*
 * jsdom ships no TouchEvent, and the composable only ever reads `touches`,
 * `target`, `timeStamp` and `cancelable` off the event - so the event carries
 * just those.
 */
const touch = (
  type: string,
  timeStamp: number,
  clientX?: number,
  clientY = 0,
) => {
  const event = new Event(type, { bubbles: true, cancelable: true });

  Object.defineProperty(event, "touches", {
    value: clientX === undefined ? [] : [{ clientX, clientY }],
  });
  Object.defineProperty(event, "timeStamp", { value: timeStamp });

  return event;
};

const render = async (
  side: SwipeToDismissSide = "left",
  enabled = ref(true),
) => {
  const state = { offset: 0, dragging: false, progress: 0 };
  const onDismiss = vi.fn();

  // A component, because the composable hangs its listeners and its clean-up
  // off the surrounding scope.
  const wrapper = mount(
    defineComponent({
      setup() {
        const panel = ref<HTMLElement>();

        const swipe = useSwipeToDismiss({ panel, side, enabled, onDismiss });

        return () => {
          state.offset = swipe.offset.value;
          state.dragging = swipe.dragging.value;
          state.progress = swipe.progress.value;

          return h("div", [
            h("nav", { ref: panel, class: "panel" }, [
              h("input", { class: "range", type: "range" }),
              h("div", { class: "slider", role: "slider" }, [
                h("div", { class: "rail" }),
              ]),
            ]),
            h("div", { class: "backdrop" }),
            // Stands in for a useSwipeActions row, which keeps the moves of a
            // swipe it has taken to itself.
            h("div", {
              class: "swipe-row",
              onTouchmove: (event: Event) => event.stopPropagation(),
            }),
          ]);
        };
      },
    }),
    { attachTo: document.body },
  );

  const panel = wrapper.find(".panel").element as HTMLElement;

  Object.defineProperty(panel, "offsetWidth", { value: PANEL_WIDTH });

  return {
    wrapper,
    state,
    onDismiss,
    panel,
    backdrop: wrapper.find(".backdrop").element as HTMLElement,
    range: wrapper.find(".range").element as HTMLElement,
    rail: wrapper.find(".rail").element as HTMLElement,
    swipeRow: wrapper.find(".swipe-row").element as HTMLElement,
  };
};

// Starts at x = 150 and moves the finger in even steps, 16ms apart.
const drag = async (from: HTMLElement, path: number[], startedAt = 0) => {
  from.dispatchEvent(touch("touchstart", startedAt, 150));

  path.forEach((x, index) => {
    from.dispatchEvent(touch("touchmove", startedAt + (index + 1) * 16, x));
  });

  await flushPromises();

  return startedAt + path.length * 16;
};

const release = async (from: HTMLElement, at: number) => {
  from.dispatchEvent(touch("touchend", at));

  await flushPromises();
};

describe("useSwipeToDismiss", () => {
  it("follows the finger towards the edge a left panel came from", async () => {
    const { state, panel, wrapper } = await render("left");

    await drag(panel, [140, 120, 90]);

    expect(state.dragging).toBe(true);
    expect(state.offset).toBe(-60);
    expect(state.progress).toBeCloseTo(60 / PANEL_WIDTH);

    wrapper.unmount();
  });

  it("follows the finger towards the edge a right panel came from", async () => {
    const { state, panel, wrapper } = await render("right");

    await drag(panel, [160, 180, 210]);

    expect(state.offset).toBe(60);

    wrapper.unmount();
  });

  it("holds the panel at the open position when dragged further in", async () => {
    const { state, panel, wrapper } = await render("left");

    await drag(panel, [165, 200]);

    expect(state.offset).toBeCloseTo(0);

    wrapper.unmount();
  });

  it("closes a panel let go past half its width", async () => {
    const { state, onDismiss, panel, wrapper } = await render("left");

    const at = await drag(panel, [130, 80, 0]);

    // Held still before lifting: this is a drag, not a flick.
    await release(panel, at + 200);

    expect(onDismiss).toHaveBeenCalledOnce();
    expect(state.dragging).toBe(false);
    expect(state.offset).toBe(0);

    wrapper.unmount();
  });

  it("springs back from a slow drag short of half its width", async () => {
    const { state, onDismiss, panel, wrapper } = await render("left");

    const at = await drag(panel, [130, 100]);

    await release(panel, at + 200);

    expect(onDismiss).not.toHaveBeenCalled();
    expect(state.offset).toBe(0);

    wrapper.unmount();
  });

  it("closes on a short flick", async () => {
    const { onDismiss, panel, wrapper } = await render("left");

    const at = await drag(panel, [135, 110]);

    await release(panel, at + 10);

    expect(onDismiss).toHaveBeenCalledOnce();

    wrapper.unmount();
  });

  it("does not read two moves a millisecond apart as a flick", async () => {
    const { onDismiss, panel, wrapper } = await render("left");

    panel.dispatchEvent(touch("touchstart", 0, 150));
    panel.dispatchEvent(touch("touchmove", 40, 138));
    panel.dispatchEvent(touch("touchmove", 80, 126));
    panel.dispatchEvent(touch("touchmove", 81, 123));
    await release(panel, 85);

    expect(onDismiss).not.toHaveBeenCalled();

    wrapper.unmount();
  });

  it("stays open when the flick back is shorter than the measured stretch", async () => {
    const { onDismiss, panel, wrapper } = await render("left");

    panel.dispatchEvent(touch("touchstart", 0, 150));
    panel.dispatchEvent(touch("touchmove", 16, 80));
    panel.dispatchEvent(touch("touchmove", 32, 100));
    await release(panel, 42);

    expect(onDismiss).not.toHaveBeenCalled();

    wrapper.unmount();
  });

  it("stays open when flicked back after a long drag", async () => {
    const { onDismiss, panel, wrapper } = await render("left");

    const at = await drag(panel, [100, 20, 0, 40]);

    await release(panel, at + 10);

    expect(onDismiss).not.toHaveBeenCalled();

    wrapper.unmount();
  });

  it("closes from a drag across the backdrop", async () => {
    const { onDismiss, backdrop, wrapper } = await render("left");

    const at = await drag(backdrop, [130, 0]);

    await release(backdrop, at + 200);

    expect(onDismiss).toHaveBeenCalledOnce();

    wrapper.unmount();
  });

  it("leaves a vertical scroll alone", async () => {
    const { state, onDismiss, panel, wrapper } = await render("left");

    panel.dispatchEvent(touch("touchstart", 0, 150, 100));
    panel.dispatchEvent(touch("touchmove", 16, 145, 160));
    panel.dispatchEvent(touch("touchmove", 32, 0, 400));
    await release(panel, 48);

    expect(state.offset).toBe(0);
    expect(onDismiss).not.toHaveBeenCalled();

    wrapper.unmount();
  });

  it("leaves a drag on a slider to the slider", async () => {
    const { state, onDismiss, range, wrapper } = await render("left");

    const at = await drag(range, [130, 0]);

    expect(state.offset).toBe(0);

    await release(range, at + 200);

    expect(onDismiss).not.toHaveBeenCalled();

    wrapper.unmount();
  });

  it("leaves a drag on a custom slider to the slider", async () => {
    const { state, onDismiss, rail, wrapper } = await render("left");

    const at = await drag(rail, [130, 0]);

    expect(state.offset).toBe(0);

    await release(rail, at + 200);

    expect(onDismiss).not.toHaveBeenCalled();

    wrapper.unmount();
  });

  it("leaves a swipe that a row keeps to itself to the row", async () => {
    const { state, onDismiss, swipeRow, wrapper } = await render("left");

    const at = await drag(swipeRow, [130, 0]);

    expect(state.offset).toBe(0);

    await release(swipeRow, at + 200);

    expect(onDismiss).not.toHaveBeenCalled();

    wrapper.unmount();
  });

  it("does nothing while the panel is closed", async () => {
    const { state, onDismiss, panel, wrapper } = await render(
      "left",
      ref(false),
    );

    const at = await drag(panel, [130, 0]);

    await release(panel, at + 200);

    expect(state.offset).toBe(0);
    expect(onDismiss).not.toHaveBeenCalled();

    wrapper.unmount();
  });
});
