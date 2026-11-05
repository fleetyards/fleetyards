import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { h } from "vue";
import { createMemoryHistory, createRouter } from "vue-router";
import type { VueWrapper } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import NavMenu from "./index.vue";
import NavMenuItem from "./Item/index.vue";

let wrapper: VueWrapper | undefined;

// jsdom lays nothing out, so without a width every menu thinks it is on a phone,
// where the rail never collapses.
beforeEach(() => {
  Object.defineProperty(document.documentElement, "clientWidth", {
    value: 1280,
    configurable: true,
  });
  // Also layout: a row with no boxes counts as hidden.
  vi.spyOn(HTMLElement.prototype, "getClientRects").mockReturnValue([
    {},
  ] as unknown as DOMRectList);
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  vi.restoreAllMocks();
});

const mountMenu = async (initialState: Record<string, unknown> = {}) => {
  wrapper = await mountWithDefaults(NavMenu, {
    attrs: { "data-test": "menu" },
    slots: {
      trigger: () => [h("span", "Open")],
      default: () => [
        h(NavMenuItem, { label: "First", "data-test": "first" }),
        h(NavMenuItem, { divider: true }),
        h(NavMenuItem, { label: "Second", "data-test": "second" }),
      ],
    },
    initialState: { nav: { slim: false }, ...initialState },
    attachTo: document.body,
  });

  return wrapper;
};

const trigger = (menu: VueWrapper) => menu.get('[data-test="menu"]');

const focused = () => document.activeElement?.getAttribute("data-test");

const press = async (menu: VueWrapper, key: string) => {
  (document.activeElement as HTMLElement).dispatchEvent(
    new KeyboardEvent("keydown", { key, bubbles: true, cancelable: true }),
  );
  await menu.vm.$nextTick();
  await menu.vm.$nextTick();
};

describe("NavMenu", () => {
  it("opens and closes from its trigger", async () => {
    const menu = await mountMenu();

    expect(menu.find(".nav-menu__panel").exists()).toBe(false);

    await trigger(menu).trigger("click");

    expect(menu.find(".nav-menu__panel").exists()).toBe(true);
    expect(trigger(menu).attributes("aria-expanded")).toBe("true");

    await trigger(menu).trigger("click");

    expect(menu.find(".nav-menu__panel").exists()).toBe(false);
  });

  it("closes on Escape and hands focus back to the trigger", async () => {
    const menu = await mountMenu();

    await trigger(menu).trigger("click");
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    await menu.vm.$nextTick();

    expect(menu.find(".nav-menu__panel").exists()).toBe(false);
    expect(document.activeElement).toBe(trigger(menu).element);
  });

  it("closes once a row is chosen", async () => {
    const menu = await mountMenu();

    await trigger(menu).trigger("click");
    await menu.get('[data-test="second"]').trigger("click");

    expect(menu.find(".nav-menu__panel").exists()).toBe(false);
  });

  it("closes on a click outside it", async () => {
    const menu = await mountMenu();

    await trigger(menu).trigger("click");
    document.body.dispatchEvent(new Event("pointerdown", { bubbles: true }));
    await menu.vm.$nextTick();

    expect(menu.find(".nav-menu__panel").exists()).toBe(false);
  });

  // On the collapsed rail the trigger is icon-sized, so the menu opens beside
  // it at a width of its own.
  it("opens beside the collapsed rail", async () => {
    const menu = await mountMenu({ nav: { slim: true } });

    await trigger(menu).trigger("click");

    expect(menu.get(".nav-menu__panel").classes()).toContain(
      "nav-menu__panel--slim",
    );
  });

  describe("from the keyboard", () => {
    it("opens and moves to the first row on the right arrow", async () => {
      const menu = await mountMenu();

      (trigger(menu).element as HTMLElement).focus();
      await press(menu, "ArrowRight");

      expect(menu.find(".nav-menu__panel").exists()).toBe(true);
      expect(focused()).toBe("first");
    });

    it("leaves the rows to the rail's arrows while it is shut", async () => {
      const menu = await mountMenu();

      (trigger(menu).element as HTMLElement).focus();
      await press(menu, "ArrowDown");

      expect(menu.find(".nav-menu__panel").exists()).toBe(false);
      expect(focused()).toBe("menu");
    });

    it("enters an open menu at either end with the vertical arrows", async () => {
      const menu = await mountMenu();

      await trigger(menu).trigger("click");
      (trigger(menu).element as HTMLElement).focus();
      await press(menu, "ArrowDown");
      expect(focused()).toBe("first");

      (trigger(menu).element as HTMLElement).focus();
      await press(menu, "ArrowUp");
      expect(focused()).toBe("second");
    });

    it("closes back to the trigger on the left arrow", async () => {
      const menu = await mountMenu();

      await trigger(menu).trigger("click");
      (trigger(menu).element as HTMLElement).focus();
      await press(menu, "ArrowDown");
      await press(menu, "ArrowLeft");

      expect(menu.find(".nav-menu__panel").exists()).toBe(false);
      expect(focused()).toBe("menu");
    });

    // The row is removed with the panel, which would drop the focus on the body.
    it("hands focus back when a row is chosen with a key", async () => {
      const menu = await mountMenu();

      await trigger(menu).trigger("click");
      // Vue drops an event dispatched in the millisecond its listener was added.
      await new Promise((resolve) => setTimeout(resolve, 2));
      menu
        .get('[data-test="second"]')
        .element.dispatchEvent(new MouseEvent("click", { bubbles: true }));
      await menu.vm.$nextTick();

      expect(focused()).toBe("menu");
    });
  });

  // RouterLink spreads its attrs over its anchor, so an undefined `href` handed
  // to it removes the one it resolved, and the row stops being a tab stop.
  it("keeps the href of a row that links to a route", async () => {
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: "/cart", name: "cart", component: { template: "<div />" } },
      ],
    });

    wrapper = await mountWithDefaults(NavMenu, {
      attrs: { "data-test": "menu" },
      slots: {
        default: () => [
          h(NavMenuItem, {
            to: { name: "cart" },
            label: "Cart",
            "data-test": "cart",
          }),
        ],
      },
      initialState: { nav: { slim: false } },
      plugins: [router],
      attachTo: document.body,
    });

    await trigger(wrapper).trigger("click");

    expect(wrapper.get('[data-test="cart"]').attributes("href")).toBeTruthy();
  });
});
