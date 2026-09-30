import { mount, type VueWrapper } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { h } from "vue";
import Popover from "./index.vue";
import { popoverLayerKey, POPOVER_BASE_LAYER } from "./layer";

const wrappers: VueWrapper[] = [];

const mountPopover = (trigger: "link" | "text" = "link", label = "Glacier") => {
  const wrapper = mount(Popover, {
    attachTo: document.body,
    props: { label },
    slots: {
      default: () =>
        trigger === "link"
          ? h("a", { href: "#target", class: "trigger-link" }, label)
          : label,
      content: () => h("div", { class: "card" }, `${label} stats`),
    },
  });

  wrappers.push(wrapper);

  return wrapper;
};

const panel = () => document.querySelector("[data-test='popover']");

const pointerover = (el: Element, pointerType: string) => {
  const event = new Event("pointerover", { bubbles: true });
  Object.assign(event, { pointerType });
  el.dispatchEvent(event);
};

const tap = (el: Element, target: Element = el) => {
  pointerover(el, "touch");
  // The synthetic hover a tap produces, dispatched before the press on
  // purpose: some browser builds order it that way, and a popover keyed on the
  // press would open on it and then close on the click.
  el.dispatchEvent(new MouseEvent("mouseenter"));
  const click = new MouseEvent("click", {
    bubbles: true,
    cancelable: true,
    detail: 1,
  });
  target.dispatchEvent(click);

  return click;
};

beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  while (wrappers.length) wrappers.pop()?.unmount();
  vi.useRealTimers();
});

describe("Popover with a mouse", () => {
  it("opens after the delay and closes after the grace period", async () => {
    const wrapper = mountPopover();
    const trigger = wrapper.find("[data-test='popover-trigger']");

    pointerover(trigger.element, "mouse");
    await trigger.trigger("mouseenter");
    expect(panel()).toBeNull();

    await vi.advanceTimersByTimeAsync(300);
    expect(panel()?.textContent).toBe("Glacier stats");

    await trigger.trigger("mouseleave");
    await vi.advanceTimersByTimeAsync(150);
    expect(panel()).toBeNull();
  });

  it("stays open while the pointer crosses into the card", async () => {
    const wrapper = mountPopover();
    const trigger = wrapper.find("[data-test='popover-trigger']");

    pointerover(trigger.element, "mouse");
    await trigger.trigger("mouseenter");
    await vi.advanceTimersByTimeAsync(300);

    await trigger.trigger("mouseleave");
    panel()!.dispatchEvent(new MouseEvent("mouseenter"));
    await vi.advanceTimersByTimeAsync(500);

    expect(panel()).not.toBeNull();
  });

  it("never opens for a pointer that only passes over", async () => {
    const wrapper = mountPopover();
    const trigger = wrapper.find("[data-test='popover-trigger']");

    pointerover(trigger.element, "mouse");
    await trigger.trigger("mouseenter");
    await vi.advanceTimersByTimeAsync(100);
    await trigger.trigger("mouseleave");
    await vi.advanceTimersByTimeAsync(500);

    expect(panel()).toBeNull();
  });

  it("lets a click follow the link", async () => {
    const wrapper = mountPopover();
    const trigger = wrapper.find("[data-test='popover-trigger']");
    pointerover(trigger.element, "mouse");

    const click = new MouseEvent("click", {
      bubbles: true,
      cancelable: true,
      detail: 1,
    });
    wrapper.find(".trigger-link").element.dispatchEvent(click);

    expect(click.defaultPrevented).toBe(false);
    expect(panel()).toBeNull();
  });
});

describe("Popover on touch", () => {
  it("opens on the first tap instead of following the link", async () => {
    const wrapper = mountPopover();
    const trigger = wrapper.find("[data-test='popover-trigger']");

    const click = tap(trigger.element, wrapper.find(".trigger-link").element);
    await vi.advanceTimersByTimeAsync(500);

    expect(click.defaultPrevented).toBe(true);
    expect(panel()).not.toBeNull();
    expect(trigger.attributes("aria-expanded")).toBe("true");
  });

  it("follows the link on a second tap", async () => {
    const wrapper = mountPopover();
    const trigger = wrapper.find("[data-test='popover-trigger']");
    const link = wrapper.find(".trigger-link").element;

    tap(trigger.element, link);
    await vi.advanceTimersByTimeAsync(0);

    const second = tap(trigger.element, link);
    await vi.advanceTimersByTimeAsync(0);

    expect(second.defaultPrevented).toBe(false);
    expect(panel()).toBeNull();
  });

  it("closes on a tap outside, but not on one inside the card", async () => {
    const wrapper = mountPopover();
    const trigger = wrapper.find("[data-test='popover-trigger']");

    tap(trigger.element);
    await vi.advanceTimersByTimeAsync(0);

    panel()!.dispatchEvent(new Event("pointerdown", { bubbles: true }));
    expect(panel()).not.toBeNull();

    document.body.dispatchEvent(new Event("pointerdown", { bubbles: true }));
    await vi.advanceTimersByTimeAsync(0);
    expect(panel()).toBeNull();
  });

  it("closes when the page scrolls", async () => {
    const wrapper = mountPopover();
    const trigger = wrapper.find("[data-test='popover-trigger']");

    tap(trigger.element);
    await vi.advanceTimersByTimeAsync(0);

    window.dispatchEvent(new Event("scroll"));
    await vi.advanceTimersByTimeAsync(0);

    expect(panel()).toBeNull();
  });

  it("keeps the tap from reaching a clickable row around it", async () => {
    const onRowClick = vi.fn();
    const row = document.createElement("div");
    row.addEventListener("click", onRowClick);
    document.body.appendChild(row);

    const wrapper = mount(Popover, {
      attachTo: row,
      props: { label: "Glacier" },
      slots: { default: "Glacier", content: "stats" },
    });
    wrappers.push(wrapper);

    tap(wrapper.find("[data-test='popover-trigger']").element);
    await vi.advanceTimersByTimeAsync(0);

    expect(onRowClick).not.toHaveBeenCalled();
    row.remove();
  });
});

describe("Popover", () => {
  it("closes on Escape", async () => {
    const wrapper = mountPopover();
    const trigger = wrapper.find("[data-test='popover-trigger']");

    tap(trigger.element);
    await vi.advanceTimersByTimeAsync(0);

    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    await vi.advanceTimersByTimeAsync(0);

    expect(panel()).toBeNull();
  });

  it("opens on keyboard focus and closes when focus leaves", async () => {
    const wrapper = mountPopover();
    const link = wrapper.find(".trigger-link");

    const matches = vi
      .spyOn(HTMLElement.prototype, "matches")
      .mockImplementation(function (this: HTMLElement, selector: string) {
        return selector === ":focus-visible";
      });

    await link.trigger("focusin");
    await vi.advanceTimersByTimeAsync(0);
    matches.mockRestore();

    expect(panel()).not.toBeNull();
    expect(link.attributes("aria-describedby")).toBe(panel()!.id);

    await link.trigger("focusout", { relatedTarget: document.body });
    await vi.advanceTimersByTimeAsync(0);

    expect(panel()).toBeNull();
    expect(link.attributes("aria-describedby")).toBeUndefined();
  });

  it("keeps only one card open at a time", async () => {
    const first = mountPopover("link", "Glacier");
    const second = mountPopover("link", "Snowblind");

    tap(first.find("[data-test='popover-trigger']").element);
    await vi.advanceTimersByTimeAsync(0);
    tap(second.find("[data-test='popover-trigger']").element);
    await vi.advanceTimersByTimeAsync(0);

    const open = document.querySelectorAll("[data-test='popover']");
    expect(open).toHaveLength(1);
    expect(open[0].textContent).toBe("Snowblind stats");
  });

  it("makes a plain-text trigger focusable, and leaves a link alone", async () => {
    const text = mountPopover("text");
    const link = mountPopover("link");
    await vi.advanceTimersByTimeAsync(0);

    expect(
      text.find("[data-test='popover-trigger']").attributes("tabindex"),
    ).toBe("0");
    expect(
      link.find("[data-test='popover-trigger']").attributes("tabindex"),
    ).toBeUndefined();
  });

  it("does nothing while disabled", async () => {
    const wrapper = mountPopover();
    await wrapper.setProps({ disabled: true });

    tap(wrapper.find("[data-test='popover-trigger']").element);
    await vi.advanceTimersByTimeAsync(500);

    expect(panel()).toBeNull();
  });
});

describe("Popover layering", () => {
  const openIn = async (layer?: number) => {
    const wrapper = mount(Popover, {
      attachTo: document.body,
      props: { label: "Glacier" },
      slots: { default: "Glacier", content: "stats" },
      global:
        layer === undefined
          ? {}
          : { provide: { [popoverLayerKey as symbol]: layer } },
    });
    wrappers.push(wrapper);

    tap(wrapper.find("[data-test='popover-trigger']").element);
    await vi.advanceTimersByTimeAsync(0);

    return (panel() as HTMLElement).style.zIndex;
  };

  it("sits above the page and below a modal by default", async () => {
    expect(Number(await openIn())).toBe(POPOVER_BASE_LAYER);
    expect(POPOVER_BASE_LAYER).toBeLessThan(1050);
  });

  it("sits one above the overlay its trigger is in", async () => {
    expect(await openIn(1050)).toBe("1051");
  });
});
