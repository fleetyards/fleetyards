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
    content: { type: [String, Boolean], default: "Delete" },
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
});
