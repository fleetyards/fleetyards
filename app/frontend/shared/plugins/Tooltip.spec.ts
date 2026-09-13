import { mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent } from "vue";
import TooltipPlugin from "./Tooltip";

const tooltips = () =>
  Array.from(document.querySelectorAll<HTMLElement>("[data-tooltip]"));

const visibleTooltips = () =>
  tooltips().filter(
    (el) => el.style.display !== "none" && el.style.opacity !== "0",
  );

// jsdom has no layout, so every element measures 0×0 and the anchor watcher
// would treat any tooltip as orphaned. Give anchors a box the tests can move
// or collapse on demand.
let anchorRect = { top: 10, left: 10, width: 100, height: 20 };

const Anchor = defineComponent({
  props: {
    content: { type: [String, Boolean, Object], default: "Delete" },
  },
  template: `<button v-tooltip="content">x</button>`,
});

const mountAnchor = (props: Record<string, unknown> = {}) => {
  const wrapper = mount(Anchor, {
    props,
    global: { plugins: [TooltipPlugin] },
    attachTo: document.body,
  });

  const el = wrapper.element as HTMLElement;
  el.getBoundingClientRect = () =>
    ({ ...anchorRect, bottom: 0, right: 0 }) as DOMRect;

  return { wrapper, el };
};

const nextFrame = () => vi.advanceTimersByTimeAsync(20);

beforeEach(() => {
  vi.useFakeTimers();
  anchorRect = { top: 10, left: 10, width: 100, height: 20 };
});

afterEach(() => {
  vi.useRealTimers();
  tooltips().forEach((el) => el.remove());
  document.body.innerHTML = "";
});

describe("v-tooltip", () => {
  it("shows on mouseenter and hides on mouseleave", async () => {
    const { el } = mountAnchor();

    el.dispatchEvent(new Event("mouseenter"));
    await nextFrame();
    expect(visibleTooltips()).toHaveLength(1);

    el.dispatchEvent(new Event("mouseleave"));
    expect(visibleTooltips()).toHaveLength(0);
  });

  it("stays hidden when the pointer leaves within the same frame", async () => {
    const { el } = mountAnchor();

    el.dispatchEvent(new Event("mouseenter"));
    el.dispatchEvent(new Event("mouseleave"));
    await nextFrame();

    expect(visibleTooltips()).toHaveLength(0);
  });

  it("follows the anchor when it moves", async () => {
    const { el } = mountAnchor();

    el.dispatchEvent(new Event("mouseenter"));
    await nextFrame();
    const [tip] = visibleTooltips();
    expect(tip).toBeDefined();
    const before = tip.style.top;

    anchorRect = { ...anchorRect, top: 400 };
    await nextFrame();

    expect(visibleTooltips()).toHaveLength(1);
    expect(tip.style.top).not.toBe(before);
  });

  it("hides once the anchor is collapsed", async () => {
    const { el } = mountAnchor();

    el.dispatchEvent(new Event("mouseenter"));
    await nextFrame();
    expect(visibleTooltips()).toHaveLength(1);

    anchorRect = { top: 0, left: 0, width: 0, height: 0 };
    await nextFrame();

    expect(visibleTooltips()).toHaveLength(0);
  });

  it("hides when the pointer moves onto an unrelated element", async () => {
    const { el } = mountAnchor();
    const other = document.createElement("div");
    document.body.appendChild(other);

    el.dispatchEvent(new Event("mouseenter"));
    await nextFrame();
    expect(visibleTooltips()).toHaveLength(1);

    other.dispatchEvent(new Event("pointerover", { bubbles: true }));
    expect(visibleTooltips()).toHaveLength(0);
  });

  it("hides on Escape", async () => {
    const { el } = mountAnchor();

    el.dispatchEvent(new Event("mouseenter"));
    await nextFrame();

    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    expect(visibleTooltips()).toHaveLength(0);
  });

  it("does not show on focus that is not keyboard driven", async () => {
    const { el } = mountAnchor();
    vi.spyOn(el, "matches").mockReturnValue(false);

    el.dispatchEvent(new Event("focus"));
    await nextFrame();

    expect(visibleTooltips()).toHaveLength(0);
  });

  it("removes its element when the anchor unmounts", async () => {
    const { wrapper, el } = mountAnchor();

    el.dispatchEvent(new Event("mouseenter"));
    await nextFrame();
    expect(tooltips()).toHaveLength(1);

    wrapper.unmount();
    expect(tooltips()).toHaveLength(0);
  });

  it("keeps at most one tooltip on screen", async () => {
    const first = mountAnchor();
    const second = mountAnchor({ content: "Edit" });

    first.el.dispatchEvent(new Event("mouseenter"));
    await nextFrame();
    second.el.dispatchEvent(new Event("mouseenter"));
    await nextFrame();

    expect(visibleTooltips()).toHaveLength(1);
  });

  it("never shows without content", async () => {
    const { el } = mountAnchor({ content: false });

    el.dispatchEvent(new Event("mouseenter"));
    await nextFrame();

    expect(visibleTooltips()).toHaveLength(0);
  });

  /*
   * Nothing in here shrinks a tooltip to fit -- positioning only slides it back
   * inside the viewport -- so a sentence on one line runs off the side of the
   * window. The hangar sync hint measures 959px unwrapped, wider than the modal
   * it explains.
   */
  it("keeps a label on one line", async () => {
    const { el } = mountAnchor({ content: "Delete" });

    el.dispatchEvent(new Event("mouseenter"));
    await nextFrame();

    const [tooltip] = visibleTooltips();
    expect(tooltip.style.whiteSpace).toBe("nowrap");
    expect(tooltip.style.maxWidth).toBe("");
  });

  /*
   * A pointer that cannot hover has only the tap to open a tooltip with, and
   * `click` was wired straight to hide -- so the tooltip a tap opened through
   * its synthetic mouse events closed again in the same gesture.
   *
   * Which pointer arrived is read from `pointerover`, the one ordering the spec
   * pins down. An earlier attempt keyed off whether `pointerdown` beat the
   * synthetic `mouseenter`; that holds in some builds and not others, and CI
   * ran one of the others.
   */
  describe("a pointer that cannot hover", () => {
    const arrive = (el: HTMLElement, pointerType: string) =>
      el.dispatchEvent(new PointerEvent("pointerover", { pointerType }));

    const tap = (el: HTMLElement, pointerType = "touch") => {
      arrive(el, pointerType);
      // Order deliberately unhelpful: the synthetic hover lands before the
      // press here, which is what CI does and what broke the previous attempt.
      el.dispatchEvent(new Event("mouseenter"));
      el.dispatchEvent(new Event("pointerdown"));
      el.dispatchEvent(new Event("click"));
    };

    it("opens on a tap and closes on the next one", async () => {
      const { el } = mountAnchor();

      tap(el);
      await nextFrame();
      expect(visibleTooltips()).toHaveLength(1);

      tap(el);
      expect(visibleTooltips()).toHaveLength(0);
    });

    // The synthetic `mouseenter` would otherwise open it a moment before the
    // click closed it again.
    it("does not open on the hover a tap synthesises", async () => {
      const { el } = mountAnchor();

      arrive(el, "touch");
      el.dispatchEvent(new Event("mouseenter"));
      await nextFrame();

      expect(visibleTooltips()).toHaveLength(0);
    });

    // A stylus cannot be assumed to hover, and being unable to read a hint is
    // worse than needing a tap for it.
    it("treats a stylus the same way", async () => {
      const { el } = mountAnchor();

      tap(el, "pen");
      await nextFrame();

      expect(visibleTooltips()).toHaveLength(1);
    });

    /*
     * The case a media query cannot answer: a touchscreen laptop reports
     * `hover: hover`, because that describes its primary pointer. The finger
     * has to decide for itself -- including when a mouse is still resting on
     * the same anchor, having already opened and closed the tooltip.
     */
    it("decides for itself with a mouse resting on the anchor", async () => {
      const { el } = mountAnchor();

      arrive(el, "mouse");
      el.dispatchEvent(new Event("mouseenter"));
      await nextFrame();
      expect(visibleTooltips()).toHaveLength(1);

      el.dispatchEvent(new Event("click"));
      expect(visibleTooltips()).toHaveLength(0);

      // No `mouseleave` -- the mouse has not moved.
      tap(el);
      await nextFrame();
      expect(visibleTooltips()).toHaveLength(1);
    });
  });

  describe("a mouse", () => {
    const hover = (el: HTMLElement) => {
      el.dispatchEvent(
        new PointerEvent("pointerover", { pointerType: "mouse" }),
      );
      el.dispatchEvent(new Event("mouseenter"));
    };

    it("still opens on hover and closes on click", async () => {
      const { el } = mountAnchor();

      hover(el);
      await nextFrame();
      expect(visibleTooltips()).toHaveLength(1);

      el.dispatchEvent(new Event("click"));
      expect(visibleTooltips()).toHaveLength(0);
    });

    // Clicking a control twice must not put its tooltip back over the result.
    it("keeps it closed on a second click", async () => {
      const { el } = mountAnchor();

      hover(el);
      await nextFrame();

      el.dispatchEvent(new Event("click"));
      el.dispatchEvent(new Event("click"));
      await nextFrame();

      expect(visibleTooltips()).toHaveLength(0);
    });

    // No pointer events at all: the tooltip behaves the way it always did.
    it("behaves as before where nothing reports a pointer type", async () => {
      const { el } = mountAnchor();

      el.dispatchEvent(new Event("mouseenter"));
      await nextFrame();
      expect(visibleTooltips()).toHaveLength(1);

      el.dispatchEvent(new Event("click"));
      expect(visibleTooltips()).toHaveLength(0);
    });
  });

  it("wraps a sentence when asked to", async () => {
    const { el } = mountAnchor({
      content: {
        content: "A whole sentence about snub crafts",
        multiline: true,
      },
    });

    el.dispatchEvent(new Event("mouseenter"));
    await nextFrame();

    const [tooltip] = visibleTooltips();
    expect(tooltip.style.whiteSpace).toBe("normal");
    expect(tooltip.style.maxWidth).toBe("280px");
  });
});
