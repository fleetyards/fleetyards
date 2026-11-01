import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { h } from "vue";
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
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
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
});
