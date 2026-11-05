import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { h } from "vue";
import Component from "./index.vue";
import { setActivePinia, createPinia } from "pinia";
import { useNavStore } from "@/shared/stores/nav";

describe("AppNavigation", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("renders", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        title: "Test",
        logo: "logo.png",
      },
    });
    expect(wrapper.exists()).toBe(true);
  });

  it("renders nothing without pagination info", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        title: "Test",
        logo: "logo.png",
      },
    });
    expect(wrapper.findAll("nav")).toHaveLength(1);
  });

  describe("from the keyboard", () => {
    const mountRail = async (clientWidth: number) => {
      Object.defineProperty(document.documentElement, "clientWidth", {
        value: clientWidth,
        configurable: true,
      });

      return mountWithDefaults<typeof Component>(Component, {
        props: { title: "Test", logo: "logo.png" },
        slots: {
          main: () => [
            h("li", [h("a", { href: "/one", "data-test": "one" }, "One")]),
            h("li", [h("button", { "data-test": "two" }, "Two")]),
            h("li", [h("a", { "data-test": "no-href" }, "No href")]),
            h("li", [
              h("a", { href: "/three", "data-test": "three" }, "Three"),
            ]),
          ],
        },
        initialState: { nav: { slim: false } },
        attachTo: document.body,
      });
    };

    const press = (key: string) =>
      (document.activeElement as HTMLElement).dispatchEvent(
        new KeyboardEvent("keydown", { key, bubbles: true, cancelable: true }),
      );

    const focused = () =>
      document.activeElement?.closest("[data-test]")?.getAttribute("data-test");

    beforeEach(() => {
      vi.spyOn(HTMLElement.prototype, "getClientRects").mockReturnValue([
        {},
      ] as unknown as DOMRectList);
    });

    afterEach(() => {
      vi.restoreAllMocks();
      document.body.innerHTML = "";
    });

    it("walks the rows with the arrows, and wraps", async () => {
      const wrapper = await mountRail(1280);

      (wrapper.get('[data-test="one"]').element as HTMLElement).focus();

      press("ArrowDown");
      expect(focused()).toBe("two");

      press("End");
      expect(focused()).toBe("nav-toggle-slim");

      press("ArrowDown");
      expect(focused()).toBe("one");

      press("ArrowUp");
      expect(focused()).toBe("nav-toggle-slim");

      press("Home");
      expect(focused()).toBe("one");

      wrapper.unmount();
    });

    it("skips what no key can reach", async () => {
      const wrapper = await mountRail(1280);

      (wrapper.get('[data-test="two"]').element as HTMLElement).focus();
      press("ArrowDown");

      expect(focused()).toBe("three");

      wrapper.unmount();
    });

    it("keeps a closed drawer out of the tab order", async () => {
      const wrapper = await mountRail(390);
      const drawer = wrapper.get(".app-navigation__wrapper");

      expect(drawer.attributes("inert")).toBeDefined();

      useNavStore(wrapper.vm.$pinia).collapsed = false;
      await wrapper.vm.$nextTick();

      expect(drawer.attributes("inert")).toBeUndefined();

      wrapper.unmount();
    });

    it("moves into the drawer, and back out of it on Escape", async () => {
      const toggle = document.body.appendChild(
        document.createElement("button"),
      );
      const wrapper = await mountRail(390);

      // The testing pinia stubs actions, so the state is what gets driven here.
      const store = useNavStore(wrapper.vm.$pinia);
      const close = vi.spyOn(store, "close");

      toggle.focus();
      store.collapsed = false;
      await wrapper.vm.$nextTick();
      await wrapper.vm.$nextTick();

      expect(focused()).toBe("one");

      window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
      expect(close).toHaveBeenCalled();

      store.collapsed = true;
      await wrapper.vm.$nextTick();

      expect(document.activeElement).toBe(toggle);

      wrapper.unmount();
    });

    it("skips to the content", async () => {
      const main = document.body.appendChild(document.createElement("div"));
      main.id = "main-content";
      main.tabIndex = -1;

      const wrapper = await mountRail(1280);

      await wrapper.get('[data-test="nav-skip-to-content"]').trigger("click");

      expect(document.activeElement).toBe(main);

      wrapper.unmount();
    });
  });
});
