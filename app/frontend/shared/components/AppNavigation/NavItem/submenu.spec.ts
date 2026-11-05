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
    it("nests the rows of the section the reader is in", async () => {
      const wrapper = await mountSection(false, { submenuActive: true });

      expect(wrapper.find("ul").exists()).toBe(true);
      expect(wrapper.find(".nav-flyout").exists()).toBe(false);

      wrapper.unmount();
    });

    it("opens any other section as the panel", async () => {
      const wrapper = await mountSection(false);

      expect(wrapper.find("ul").exists()).toBe(false);

      await wrapper.trigger("pointerenter");

      expect(wrapper.find(".nav-flyout").exists()).toBe(true);

      wrapper.unmount();
    });

    /*
     * The group used to be fenced by the same element that separates one
     * top-level section from another, so a submenu read as a new section rather
     * than as rows belonging to the row above it. The rail replaced them.
     */
    it("fences its rows with a rail, not with dividers", async () => {
      const wrapper = await mountSection(false, { submenuActive: true });

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

    // Escape hands focus back to the trigger, which must not reopen the panel
    // on the same key that closed it.
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

    // The rail has no width to nest in, so even the section the reader is in
    // opens beside it rather than unfolding under the icon.
    it("opens the section the reader is in as the panel too", async () => {
      const wrapper = await mountSection(true, { submenuActive: true });

      await wrapper.trigger("pointerenter");

      expect(wrapper.findAll(".nav-flyout")).toHaveLength(1);
      expect(wrapper.find("li > ul").exists()).toBe(false);

      wrapper.unmount();
    });
  });

  describe("a sub-section inside a panel", () => {
    const mountNested = () =>
      mountWithDefaults<typeof NavItem>(NavItem, {
        props: { label: "Hangar", menuKey: "hangar-menu" },
        slots: {
          submenu: () => [
            h(
              NavItem,
              { label: "Pledge items", menuKey: "pledge-menu" },
              {
                submenu: () => [
                  h(NavItem, { to: { name: "components" }, label: "Paints" }),
                ],
              },
            ),
          ],
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
        } as any,
        initialState: { nav: { slim: true } },
        plugins: [buildRouter()],
        attachTo: document.body,
      });

    // One panel at a time would close the section's the moment its
    // sub-section opened, taking the sub-section with it.
    it("keeps the panel it was opened from", async () => {
      const wrapper = await mountNested();

      await wrapper
        .get('[data-test="nav-hangar-menu"] > button')
        .trigger("click");
      await wrapper
        .get('[data-test="nav-pledge-menu"] > button')
        .trigger("click");

      const panels = wrapper.findAll(".nav-flyout");

      expect(panels).toHaveLength(2);
      expect(panels[0].classes()).toContain("nav-flyout--nesting");

      wrapper.unmount();
    });
  });

  describe("from the keyboard", () => {
    const panelCount = (wrapper: VueWrapper) =>
      wrapper.findAll(".nav-flyout").length;

    const press = async (wrapper: VueWrapper, key: string) => {
      (document.activeElement as HTMLElement).dispatchEvent(
        new KeyboardEvent("keydown", { key, bubbles: true, cancelable: true }),
      );
      await wrapper.vm.$nextTick();
      await wrapper.vm.$nextTick();
      await wrapper.vm.$nextTick();
    };

    const focusTrigger = (wrapper: VueWrapper, key: string) =>
      (
        wrapper.get(`[data-test="nav-${key}"] > button`)
          .element as HTMLButtonElement
      ).focus();

    beforeEach(() => {
      vi.spyOn(HTMLElement.prototype, "getClientRects").mockReturnValue([
        {},
      ] as unknown as DOMRectList);
    });

    // Opening on focus had Tab walk every row of every section, 41 stops to get
    // from the top of the rail to the bottom.
    it("does not open a section when the focus lands on it", async () => {
      const wrapper = await mountSection(true);

      focusTrigger(wrapper, "catalogue-menu");
      await wrapper.vm.$nextTick();

      expect(panelCount(wrapper)).toBe(0);

      wrapper.unmount();
    });

    it("opens the panel and enters it on the right arrow", async () => {
      const wrapper = await mountSection(true);

      focusTrigger(wrapper, "catalogue-menu");
      await press(wrapper, "ArrowRight");

      expect(panelCount(wrapper)).toBe(1);
      expect(document.activeElement?.textContent).toContain("Components");

      wrapper.unmount();
    });

    it("closes back to the trigger on the left arrow", async () => {
      const wrapper = await mountSection(true);

      focusTrigger(wrapper, "catalogue-menu");
      await press(wrapper, "ArrowRight");
      await press(wrapper, "ArrowLeft");

      expect(panelCount(wrapper)).toBe(0);
      expect(document.activeElement).toBe(
        wrapper.get('[data-test="nav-catalogue-menu"] > button').element,
      );

      wrapper.unmount();
    });

    it("folds a section that is unfolded in place", async () => {
      const wrapper = await mountSection(false, { submenuActive: true });
      const section = '[data-test="nav-catalogue-menu"] > button';

      focusTrigger(wrapper, "catalogue-menu");
      expect(wrapper.get(section).attributes("aria-expanded")).toBe("true");

      await press(wrapper, "ArrowLeft");

      expect(wrapper.get(section).attributes("aria-expanded")).toBe("false");

      wrapper.unmount();
    });

    it("does not take the focus from elsewhere on the page", async () => {
      const wrapper = await mountSection(true);
      const input = document.body.appendChild(document.createElement("input"));

      await wrapper.trigger("pointerenter");
      input.focus();
      document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
      await wrapper.vm.$nextTick();

      expect(panelCount(wrapper)).toBe(0);
      expect(document.activeElement).toBe(input);

      input.remove();
      wrapper.unmount();
    });

    it("marks the row of the open page", async () => {
      const wrapper = await mountWithDefaults<typeof NavItem>(NavItem, {
        props: { to: { name: "home" }, label: "Home", active: true },
        plugins: [buildRouter()],
      });

      expect(wrapper.get("a").attributes("aria-current")).toBe("page");

      wrapper.unmount();
    });

    describe("in a sub-section's panel", () => {
      const mountNested = () =>
        mountWithDefaults<typeof NavItem>(NavItem, {
          props: { label: "Hangar", menuKey: "hangar-menu" },
          slots: {
            submenu: () => [
              h(
                NavItem,
                { label: "Pledge items", menuKey: "pledge-menu" },
                {
                  submenu: () => [
                    h(NavItem, { to: { name: "components" }, label: "Paints" }),
                  ],
                },
              ),
            ],
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
          } as any,
          initialState: { nav: { slim: true } },
          plugins: [buildRouter()],
          attachTo: document.body,
        });

      for (const key of ["Escape", "ArrowLeft"]) {
        it(`closes one panel per press of ${key}`, async () => {
          const wrapper = await mountNested();

          focusTrigger(wrapper, "hangar-menu");
          await press(wrapper, "ArrowRight");
          await press(wrapper, "ArrowRight");
          expect(panelCount(wrapper)).toBe(2);

          await press(wrapper, key);
          expect(panelCount(wrapper)).toBe(1);
          expect(document.activeElement).toBe(
            wrapper.get('[data-test="nav-pledge-menu"] > button').element,
          );

          wrapper.unmount();
        });
      }
    });
  });

  describe("two sub-sections, one under the other", () => {
    const mountSiblings = () =>
      mountWithDefaults<typeof NavItem>(NavItem, {
        props: { label: "Hangar", menuKey: "hangar-menu" },
        slots: {
          submenu: () =>
            ["assets", "pledge"].map((key) =>
              h(
                NavItem,
                { label: key, menuKey: key },
                {
                  submenu: () => [
                    h(NavItem, { to: { name: "components" }, label: key }),
                  ],
                },
              ),
            ),
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
        } as any,
        initialState: { nav: { slim: true } },
        plugins: [buildRouter()],
        attachTo: document.body,
      });

    const title = (wrapper: VueWrapper) =>
      wrapper.findAll(".nav-flyout__title").map((item) => item.text());

    const assetsOpenWithPanelAt = async (wrapper: VueWrapper) => {
      await wrapper
        .get('[data-test="nav-hangar-menu"] > button')
        .trigger("click");
      await wrapper.get('[data-test="nav-assets"]').trigger("pointerenter");
      await wrapper.vm.$nextTick();

      const panel = wrapper.findAll(".nav-flyout")[1].element;

      panel.getBoundingClientRect = () =>
        ({ left: 300, top: 100, bottom: 220 }) as DOMRect;
    };

    const pointer = async (
      wrapper: VueWrapper,
      row: string,
      type: string,
      x: number,
      y: number,
    ) => {
      wrapper.get(`[data-test="nav-${row}"]`).element.dispatchEvent(
        new MouseEvent(type, {
          clientX: x,
          clientY: y,
          bubbles: type === "pointermove",
        }),
      );
      await wrapper.vm.$nextTick();
    };

    const onPledge = async (wrapper: VueWrapper) => {
      await pointer(wrapper, "assets", "pointerleave", 100, 130);
      await pointer(wrapper, "pledge", "pointerenter", 110, 140);
    };

    const movePointer = (wrapper: VueWrapper, x: number, y: number) =>
      pointer(wrapper, "pledge", "pointermove", x, y);

    beforeEach(() => {
      document.elementFromPoint = () => document.body;
    });

    it("keeps the open panel while the pointer crosses towards it", async () => {
      const wrapper = await mountSiblings();

      await assetsOpenWithPanelAt(wrapper);
      await onPledge(wrapper);

      for (let step = 1; step <= 8; step += 1) {
        await movePointer(wrapper, 110 + step * 20, 140 + step * 2);
        await vi.advanceTimersByTimeAsync(100);
      }

      expect(title(wrapper)).toEqual(["Hangar", "assets"]);

      wrapper.unmount();
    });

    it("opens the row a pointer stops on", async () => {
      const wrapper = await mountSiblings();

      await assetsOpenWithPanelAt(wrapper);
      await onPledge(wrapper);

      await vi.advanceTimersByTimeAsync(250);
      await wrapper.vm.$nextTick();

      expect(title(wrapper)).toEqual(["Hangar", "pledge"]);

      wrapper.unmount();
    });

    it("opens the row a pointer moves along instead of out", async () => {
      const wrapper = await mountSiblings();

      await assetsOpenWithPanelAt(wrapper);
      await onPledge(wrapper);
      await movePointer(wrapper, 105, 170);

      await vi.advanceTimersByTimeAsync(250);
      await wrapper.vm.$nextTick();

      expect(title(wrapper)).toEqual(["Hangar", "pledge"]);

      wrapper.unmount();
    });

    it("waits for a slow pointer however long it takes", async () => {
      const wrapper = await mountSiblings();

      await assetsOpenWithPanelAt(wrapper);
      await onPledge(wrapper);

      for (let step = 1; step <= 90; step += 1) {
        await movePointer(wrapper, 110 + step * 2, 140 + (step % 2));
        await vi.advanceTimersByTimeAsync(50);
      }

      expect(title(wrapper)).toEqual(["Hangar", "assets"]);

      wrapper.unmount();
    });

    it("keeps every panel for a pointer resting between two of them", async () => {
      const wrapper = await mountSiblings();

      await assetsOpenWithPanelAt(wrapper);

      const bridge = wrapper.get(
        '[data-test="nav-assets"] .nav-flyout__bridge',
      );

      document.elementFromPoint = () => bridge.element;

      wrapper
        .findAll(".nav-flyout")[1]
        .element.dispatchEvent(new MouseEvent("pointerleave"));
      wrapper
        .findAll(".nav-flyout")[0]
        .element.dispatchEvent(new MouseEvent("pointerleave"));

      await vi.advanceTimersByTimeAsync(2000);
      await wrapper.vm.$nextTick();

      expect(title(wrapper)).toEqual(["Hangar", "assets"]);

      wrapper.unmount();
    });

    it("stays open when a press in the panel takes the focus nowhere", async () => {
      const wrapper = await mountSiblings();

      await assetsOpenWithPanelAt(wrapper);
      await wrapper
        .get('[data-test="nav-assets"]')
        .trigger("focusout", { relatedTarget: null });

      expect(title(wrapper)).toEqual(["Hangar", "assets"]);

      wrapper.unmount();
    });

    it("closes when the keyboard moves on to something outside", async () => {
      const wrapper = await mountSiblings();

      await assetsOpenWithPanelAt(wrapper);
      await wrapper
        .get('[data-test="nav-assets"]')
        .trigger("focusout", { relatedTarget: document.body });

      expect(title(wrapper)).toEqual([]);

      wrapper.unmount();
    });

    // Focus bubbles, so the press that focuses a row also reaches the section
    // around it -- which must not reclaim the panel the row is in before the
    // press has become a click.
    it("keeps a sub-section's panel when a row in it takes the focus", async () => {
      const wrapper = await mountSiblings();

      await assetsOpenWithPanelAt(wrapper);
      await wrapper
        .get('[data-test="nav-assets"] .nav-flyout a')
        .trigger("focusin");

      expect(title(wrapper)).toEqual(["Hangar", "assets"]);

      wrapper.unmount();
    });
  });
});
