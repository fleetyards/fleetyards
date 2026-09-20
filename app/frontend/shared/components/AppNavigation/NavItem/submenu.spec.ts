import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { h } from "vue";
import type { VueWrapper } from "@vue/test-utils";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { useNavStore } from "@/shared/stores/nav";
import NavItem from "./index.vue";

const page = { template: "<div />" };

const buildRouter = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: page },
      { path: "/components", name: "components", component: page },
      { path: "/blueprints", name: "blueprints", component: page },
    ],
  });

/*
 * `slim` is the store's flag *and* a viewport question -- `useMobile` writes the
 * measurement into its own store on mount, and jsdom lays nothing out, so
 * `clientWidth` reads 0 and every row would think it is on a phone.
 */
const atDesktopWidth = () => {
  Object.defineProperty(document.documentElement, "clientWidth", {
    value: 1280,
    configurable: true,
  });
};

const mountSection = (slim: boolean, props: Record<string, unknown> = {}) =>
  mountWithDefaults<typeof NavItem>(NavItem, {
    props: { label: "Catalogue", menuKey: "catalogue-menu", ...props },
    slots: {
      submenu: () => [
        h(NavItem, { to: { name: "components" }, label: "Components" }),
        h(NavItem, { to: { name: "blueprints" }, label: "Blueprints" }),
      ],
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any,
    initialState: { nav: { slim } },
    plugins: [buildRouter()],
    attachTo: document.body,
  });

/*
 * The panel gives a pointer a moment to cross the gap between the row and the
 * panel before it takes the close seriously. Driven rather than waited out: a
 * real 300ms sleep against a 220ms timer is only ever as reliable as the
 * machine is idle, and it failed on a loaded one.
 */
const waitOutTheGrace = async (wrapper: VueWrapper) => {
  await vi.advanceTimersByTimeAsync(400);
  await wrapper.vm.$nextTick();
};

describe("NavItem with a submenu", () => {
  beforeEach(() => {
    atDesktopWidth();
    // After mounting would be tidier, but the mount itself schedules nothing --
    // and a faked clock in place for it costs nothing either.
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  /*
   * The trigger controls the nested list in one mode and the panel beside it in
   * the other, and it is the same button either way -- so what it reports has
   * to follow the mode, and it may only name an element that is in the
   * document.
   */
  describe("what the trigger reports", () => {
    it("names the list it controls, and whether it is open", async () => {
      const wrapper = await mountSection(false, { submenuActive: true });
      const button = wrapper.get("button");

      expect(button.attributes("aria-expanded")).toBe("true");
      expect(button.attributes("aria-controls")).toBe(
        "catalogue-menu-sub-menu",
      );
      expect(wrapper.get("ul").attributes("id")).toBe(
        "catalogue-menu-sub-menu",
      );

      wrapper.unmount();
    });

    it("says the panel is shut, and names nothing, until it opens", async () => {
      const wrapper = await mountSection(true);
      const button = wrapper.get("button");

      expect(button.attributes("aria-expanded")).toBe("false");
      expect(button.attributes("aria-controls")).toBeUndefined();

      await wrapper.trigger("pointerenter");

      expect(button.attributes("aria-expanded")).toBe("true");
      expect(button.attributes("aria-controls")).toBe(
        "catalogue-menu-sub-menu",
      );
      expect(wrapper.get(".nav-flyout").attributes("id")).toBe(
        "catalogue-menu-sub-menu",
      );

      wrapper.unmount();
    });
  });

  describe("expanded", () => {
    it("nests its rows inline rather than beside the navigation", async () => {
      const wrapper = await mountSection(false);

      expect(wrapper.find("ul").exists()).toBe(true);
      expect(wrapper.find(".nav-flyout").exists()).toBe(false);

      wrapper.unmount();
    });

    /*
     * The group used to be fenced by the same element that separates one
     * top-level section from another, so a submenu read as a new section rather
     * than as rows belonging to the row above it. The rail replaced them.
     */
    it("fences its rows with a rail, not with dividers", async () => {
      const wrapper = await mountSection(false);

      expect(wrapper.find("ul .nav-item__divider").exists()).toBe(false);

      wrapper.unmount();
    });
  });

  describe("collapsed to the icon rail", () => {
    /*
     * The chevron was the only thing separating a section from a page, and it
     * was dropped with the labels -- so a collapsed rail offered no way at all
     * to tell that a row led anywhere but to a page.
     */
    it("still marks the row as leading somewhere", async () => {
      const wrapper = await mountSection(true);

      expect(wrapper.find(".nav-item__submenu-icon").exists()).toBe(true);

      wrapper.unmount();
    });

    it("opens its rows beside the rail on hover", async () => {
      const wrapper = await mountSection(true);

      expect(wrapper.find(".nav-flyout").exists()).toBe(false);

      await wrapper.trigger("pointerenter");

      expect(wrapper.find(".nav-flyout").exists()).toBe(true);
      expect(wrapper.find(".nav-flyout__title").text()).toBe("Catalogue");

      wrapper.unmount();
    });

    /*
     * The point of the panel: a row inside one reads the section's expansion
     * rather than the store, so it carries its label even though the rail
     * behind it carries none.
     */
    it("labels the rows in the panel", async () => {
      const wrapper = await mountSection(true);

      await wrapper.trigger("pointerenter");

      const labels = wrapper
        .findAll(".nav-flyout .nav-item-text")
        .map((item) => item.text());

      expect(labels).toEqual(["Components", "Blueprints"]);

      wrapper.unmount();
    });

    /*
     * The panel is a child of the row's `li`, so a pointer arriving from the
     * panel never left the `li` and `pointerenter` does not fire again. The
     * close the panel scheduled as the pointer left it therefore had nothing to
     * cancel it, and ran while the pointer sat on the row.
     */
    it("keeps the panel open when the pointer goes back to the row", async () => {
      const wrapper = await mountSection(true);

      await wrapper.trigger("pointerenter");
      expect(wrapper.find(".nav-flyout").exists()).toBe(true);

      // Answering for the row itself: the pointer ended up inside the section.
      const row = wrapper.element as HTMLElement;
      document.elementFromPoint = () => row;

      await wrapper.find(".nav-flyout").trigger("pointerleave");

      await waitOutTheGrace(wrapper);

      expect(wrapper.find(".nav-flyout").exists()).toBe(true);

      wrapper.unmount();
    });

    it("closes once the pointer is somewhere else entirely", async () => {
      const wrapper = await mountSection(true);

      await wrapper.trigger("pointerenter");

      document.elementFromPoint = () => document.body;

      await wrapper.find(".nav-flyout").trigger("pointerleave");

      await waitOutTheGrace(wrapper);

      expect(wrapper.find(".nav-flyout").exists()).toBe(false);

      wrapper.unmount();
    });

    it("keeps the panel open while the pointer crosses into it", async () => {
      const wrapper = await mountSection(true);

      await wrapper.trigger("pointerenter");
      await wrapper.trigger("pointerleave");
      await wrapper.find(".nav-flyout").trigger("pointerenter");

      await waitOutTheGrace(wrapper);

      expect(wrapper.find(".nav-flyout").exists()).toBe(true);

      wrapper.unmount();
    });

    /*
     * Escape hands focus back to the trigger, and that is itself a `focusin` on
     * the row -- so without something to say the section was dismissed on
     * purpose, the panel reopens on the same key that closed it and a keyboard
     * cannot get out of it at all.
     */
    it("closes the panel on escape and leaves it closed", async () => {
      const wrapper = await mountSection(true);

      await wrapper.trigger("pointerenter");
      expect(wrapper.find(".nav-flyout").exists()).toBe(true);

      document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
      await wrapper.vm.$nextTick();

      expect(wrapper.find(".nav-flyout").exists()).toBe(false);

      await wrapper.trigger("focusin");

      expect(wrapper.find(".nav-flyout").exists()).toBe(false);

      wrapper.unmount();
    });

    // Dismissing is for as long as the reader stays on the row -- leaving it
    // and coming back is a fresh ask for the section.
    it("opens again once the pointer has left and returned", async () => {
      const wrapper = await mountSection(true);

      await wrapper.trigger("pointerenter");
      document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
      await wrapper.vm.$nextTick();

      await wrapper.trigger("pointerleave");
      await wrapper.trigger("pointerenter");

      expect(wrapper.find(".nav-flyout").exists()).toBe(true);

      wrapper.unmount();
    });

    /*
     * Expanding the rail unmounts the panel but says nothing about the state
     * behind it. Left open, the section would hand back a panel nobody asked
     * for the moment the rail collapsed again -- and its listeners would stay
     * bound to the document in between.
     */
    it("does not hand the panel back when the rail expands and collapses", async () => {
      const wrapper = await mountSection(true);
      const navStore = useNavStore();

      await wrapper.trigger("pointerenter");
      expect(wrapper.find(".nav-flyout").exists()).toBe(true);

      navStore.slim = false;
      await wrapper.vm.$nextTick();
      expect(wrapper.find(".nav-flyout").exists()).toBe(false);

      navStore.slim = true;
      await wrapper.vm.$nextTick();

      expect(wrapper.find(".nav-flyout").exists()).toBe(false);

      wrapper.unmount();
    });

    // The rail has no room to nest in, so the section must not also try to
    // expand in place underneath the icon.
    it("does not expand in place as well", async () => {
      const wrapper = await mountSection(true, { submenuActive: true });

      await wrapper.trigger("pointerenter");

      expect(wrapper.findAll(".nav-flyout")).toHaveLength(1);
      expect(wrapper.find("li > ul").exists()).toBe(false);

      wrapper.unmount();
    });
  });
});
