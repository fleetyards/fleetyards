import { mount, type VueWrapper } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { h } from "vue";
import Popover from "./index.vue";
import {
  popoverLayerKey,
  POPOVER_BASE_LAYER,
  POPOVER_SHEET_LAYER,
} from "./layer";

const wrappers: VueWrapper[] = [];

const mountPopover = (trigger: "link" | "text" = "link", label = "Glacier") => {
  const wrapper = mount(Popover, {
    attachTo: document.body,
    props: { label },
    global: { stubs: { AppModalCloseBtn: true } },
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

describe("Popover whose trigger only opens its card", () => {
  const mountToggling = () => {
    const wrapper = mount(Popover, {
      attachTo: document.body,
      props: { label: "Glacier", clickToggles: true },
      slots: {
        default: () => h("button", { type: "button" }, "Info"),
        content: () => h("div", "Glacier stats"),
      },
    });
    wrappers.push(wrapper);

    return wrapper.find("[data-test='popover-trigger']");
  };

  const click = async (el: Element) => {
    el.dispatchEvent(new MouseEvent("click", { bubbles: true, detail: 1 }));
    await vi.advanceTimersByTimeAsync(0);
  };

  it("opens on a mouse click without the hover delay, and closes on the next", async () => {
    const trigger = mountToggling();

    await click(trigger.element);
    expect(panel()).not.toBeNull();

    await click(trigger.element);
    expect(panel()).toBeNull();
  });

  it("closes a card a mouse click opened when the pointer leaves", async () => {
    const trigger = mountToggling();

    await click(trigger.element);
    await trigger.trigger("mouseleave");
    await vi.advanceTimersByTimeAsync(150);

    expect(panel()).toBeNull();
  });
});

describe("Popover on touch", () => {
  it("leaves a tap to the control around it when told to", async () => {
    const wrapper = mount(Popover, {
      attachTo: document.body,
      props: { label: "Glacier", tapThrough: true },
      slots: {
        default: () => "Glacier",
        content: () => h("div", "Glacier stats"),
      },
    });
    wrappers.push(wrapper);

    const clicked = vi.fn();
    document.body.addEventListener("click", clicked);
    tap(wrapper.find("[data-test='popover-trigger']").element);
    await wrapper.vm.$nextTick();
    document.body.removeEventListener("click", clicked);

    expect(clicked).toHaveBeenCalledTimes(1);
    expect(panel()).toBeNull();
  });

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

  // A finger dragged across a card taller than the space under it scrolls the
  // page; that is reading the card, not leaving it.
  it("stays open when the page scrolls under a touch on the card", async () => {
    const wrapper = mountPopover();
    const trigger = wrapper.find("[data-test='popover-trigger']");

    tap(trigger.element);
    await vi.advanceTimersByTimeAsync(0);

    panel()!.dispatchEvent(new Event("pointerdown", { bubbles: true }));
    window.dispatchEvent(new Event("scroll"));
    await vi.advanceTimersByTimeAsync(0);

    expect(panel()).not.toBeNull();
  });

  it("keeps the second tap from reaching a clickable row around it too", async () => {
    const onRowClick = vi.fn();
    const row = document.createElement("div");
    row.addEventListener("click", onRowClick);
    document.body.appendChild(row);

    const wrapper = mount(Popover, {
      attachTo: row,
      props: { label: "Door" },
      slots: { default: "Door", content: "stats" },
    });
    wrappers.push(wrapper);
    const trigger = wrapper.find("[data-test='popover-trigger']").element;

    tap(trigger);
    await vi.advanceTimersByTimeAsync(0);
    const second = tap(trigger);
    await vi.advanceTimersByTimeAsync(0);

    expect(panel()).toBeNull();
    expect(second.defaultPrevented).toBe(false);
    expect(onRowClick).not.toHaveBeenCalled();
    row.remove();
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

  it("adds to what the control is already described by, and hands it back", async () => {
    const wrapper = mountPopover();
    const link = wrapper.find(".trigger-link");
    link.element.setAttribute("aria-describedby", "own-details");

    const matches = vi
      .spyOn(HTMLElement.prototype, "matches")
      .mockImplementation(function (this: HTMLElement, selector: string) {
        return selector === ":focus-visible";
      });

    await link.trigger("focusin");
    await vi.advanceTimersByTimeAsync(0);
    matches.mockRestore();

    expect(link.attributes("aria-describedby")).toBe(
      `own-details ${panel()!.id}`,
    );

    await link.trigger("focusout", { relatedTarget: document.body });
    await vi.advanceTimersByTimeAsync(0);

    expect(link.attributes("aria-describedby")).toBe("own-details");
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

  it("stays where it opened when the cursor moves over the trigger", async () => {
    const wrapper = mountPopover();
    const el = wrapper.find(".popover__trigger").element;
    const pointerAt = (clientX: number) => {
      const event = new Event("pointerover", { bubbles: true });
      Object.assign(event, { pointerType: "mouse", clientX, clientY: 20 });
      el.dispatchEvent(event);
    };

    pointerAt(100);
    el.dispatchEvent(new MouseEvent("mouseenter"));
    await vi.advanceTimersByTimeAsync(300);

    const opened = (panel() as HTMLElement).style.left;

    pointerAt(500);
    window.dispatchEvent(new Event("resize"));
    await vi.advanceTimersByTimeAsync(0);

    expect((panel() as HTMLElement).style.left).toBe(opened);
  });
});

describe("Popover on a phone", () => {
  const phoneWidth = (matches: boolean) => {
    window.matchMedia = vi.fn().mockReturnValue({
      matches,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    });
  };

  // A browser leaves focus handed back after a tap out of :focus-visible, while
  // jsdom matches it on any focused element and would reopen the card.
  beforeEach(() => {
    vi.spyOn(HTMLElement.prototype, "matches").mockImplementation(function (
      this: HTMLElement,
      selector: string,
    ) {
      return selector === ":focus-visible"
        ? false
        : Element.prototype.matches.call(this, selector);
    });
  });

  afterEach(() => {
    Reflect.deleteProperty(window, "matchMedia");
    vi.restoreAllMocks();
  });

  const openByTap = async () => {
    const wrapper = mountPopover();

    tap(wrapper.find("[data-test='popover-trigger']").element);
    await vi.advanceTimersByTimeAsync(0);

    return wrapper;
  };

  const scrim = () => document.querySelector("[data-test='popover-scrim']");

  it("opens a tap as a sheet above the navigation", async () => {
    phoneWidth(true);

    await openByTap();

    const sheet = panel() as HTMLElement;

    expect(sheet.classList).toContain("popover--sheet");
    expect(sheet.style.top).toBe("");
    expect(sheet.style.zIndex).toBe(`${POPOVER_SHEET_LAYER}`);
    expect(scrim()).not.toBeNull();
  });

  it("takes focus as a dialog and hands it back on closing", async () => {
    phoneWidth(true);

    await openByTap();

    expect(document.activeElement).toBe(panel());
    expect((panel() as HTMLElement).getAttribute("aria-modal")).toBe("true");

    (scrim() as HTMLElement).click();
    await vi.advanceTimersByTimeAsync(0);

    expect(document.activeElement?.classList).toContain("trigger-link");
  });

  it("closes from the scrim's click, not its press", async () => {
    phoneWidth(true);

    await openByTap();

    scrim()?.dispatchEvent(new Event("pointerdown", { bubbles: true }));
    await vi.advanceTimersByTimeAsync(0);
    expect(panel()).not.toBeNull();

    (scrim() as HTMLElement).click();
    await vi.advanceTimersByTimeAsync(0);
    expect(panel()).toBeNull();
    expect(scrim()).toBeNull();
  });

  describe("swiping", () => {
    const touch = (
      type: string,
      clientY?: number,
      timeStamp = 0,
      drift = 0,
    ) => {
      const event = new Event(type, { bubbles: true, cancelable: true });
      Object.assign(event, {
        touches: clientY === undefined ? [] : [{ clientX: drift, clientY }],
      });
      Object.defineProperty(event, "timeStamp", { value: timeStamp });
      panel()?.dispatchEvent(event);
    };

    const swipe = async (distance: number, duration = 1000) => {
      touch("touchstart", 200, 0);
      touch("touchmove", 200 + distance, duration);
      await vi.advanceTimersByTimeAsync(0);
      const pulled = (panel() as HTMLElement).style.transform;
      touch("touchend", undefined, duration);
      await vi.advanceTimersByTimeAsync(0);

      return pulled;
    };

    it("follows the finger and closes past the distance", async () => {
      phoneWidth(true);
      await openByTap();

      expect(await swipe(120)).toBe("translateY(120px)");
      expect(panel()).toBeNull();
    });

    it("springs back from a short, slow pull", async () => {
      phoneWidth(true);
      await openByTap();

      await swipe(50);

      expect(panel()).not.toBeNull();
      expect((panel() as HTMLElement).style.transform).toBe("");
    });

    it("closes on a short flick", async () => {
      phoneWidth(true);
      await openByTap();

      await swipe(50, 50);

      expect(panel()).toBeNull();
    });

    it("leaves a card scrolled down to scroll", async () => {
      phoneWidth(true);
      await openByTap();

      (panel() as HTMLElement).scrollTop = 40;
      await swipe(150);

      expect(panel()).not.toBeNull();
    });

    it("leaves a sideways swipe alone", async () => {
      phoneWidth(true);
      await openByTap();

      touch("touchstart", 200, 0);
      touch("touchmove", 215, 100, 80);
      await vi.advanceTimersByTimeAsync(0);

      expect((panel() as HTMLElement).style.transform).toBe("");
    });

    it("holds the page still only while a sheet is up", async () => {
      phoneWidth(true);
      await openByTap();

      expect(document.body.style.overflow).toBe("hidden");

      (scrim() as HTMLElement).click();
      await vi.advanceTimersByTimeAsync(0);

      expect(document.body.style.overflow).not.toBe("hidden");
    });

    it("does not move an anchored card", async () => {
      phoneWidth(false);
      await openByTap();

      expect(await swipe(150)).toBe("");
      expect(panel()).not.toBeNull();
    });
  });

  it("stays anchored on a wider screen", async () => {
    phoneWidth(false);

    await openByTap();

    expect((panel() as HTMLElement).classList).not.toContain("popover--sheet");
    expect(scrim()).toBeNull();
  });

  it("stays anchored when a mouse opens it, whatever the width", async () => {
    phoneWidth(true);

    const wrapper = mountPopover();
    const trigger = wrapper.find("[data-test='popover-trigger']");

    pointerover(trigger.element, "mouse");
    await trigger.trigger("mouseenter");
    await vi.advanceTimersByTimeAsync(300);

    expect((panel() as HTMLElement).classList).not.toContain("popover--sheet");
  });
});
