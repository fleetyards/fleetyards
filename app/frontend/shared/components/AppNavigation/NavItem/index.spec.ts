import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount } from "@vue/test-utils";
import { setActivePinia, createPinia } from "pinia";

// The item reads the route to mark the open page. The action branch never does,
// but the setup runs whichever branch renders.
vi.mock("vue-router", () => ({
  useRoute: () => ({ name: "home" }),
}));

import NavItem from "./index.vue";
import { useNavStore } from "@/shared/stores/nav";

const mountItem = (props: Record<string, unknown>) =>
  mount(NavItem, {
    props,
    // The tooltip is a directive the app installs as a plugin; nothing the item
    // decides depends on it.
    global: { directives: { tooltip: {} } },
    attachTo: document.body,
  });

// The real directive is a plugin the app installs. Standing in for it with one
// that writes the content onto the element is the only way to see what the item
// asked for -- a bare `{}` stub swallows the binding.
const mountWithTooltip = (props: Record<string, unknown>) =>
  mount(NavItem, {
    props,
    global: {
      directives: {
        tooltip: {
          mounted(el: HTMLElement, binding: { value?: { content?: string } }) {
            if (binding.value?.content)
              el.dataset.tooltip = binding.value.content;
          },
        },
      },
    },
    attachTo: document.body,
  });

describe("NavItem", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  // A row whose slot carries something its label does not say -- the build
  // switch shows an environment, and two builds of one environment look
  // identical there -- has nowhere else to put it while the navigation is open.
  describe("the tooltip", () => {
    it("is shown expanded when the row asks for one", () => {
      const wrapper = mountWithTooltip({
        action: vi.fn(),
        label: "Data Source",
        tooltip: "Data Source: 4.10.0-live.12519617",
      });

      expect(wrapper.get("button").attributes("data-tooltip")).toBe(
        "Data Source: 4.10.0-live.12519617",
      );
    });

    // What every other row does: the label is the tooltip only once the words
    // are gone, and this must not start tooltipping rows that read fine.
    it("stays off an expanded row that only has a label", () => {
      const wrapper = mountWithTooltip({ action: vi.fn(), label: "Logout" });

      expect(wrapper.get("button").attributes("data-tooltip")).toBeUndefined();
    });
  });

  // An anchor with no href is not a tab stop and answers to no key, so a row
  // built that way -- logout, the collapse toggle, the build switch -- could
  // only ever be reached with a pointer. A button is both for free.
  describe("an action row", () => {
    it("takes focus", () => {
      const wrapper = mountItem({ action: vi.fn(), label: "Logout" });

      const button = wrapper.get("button");
      button.element.focus();

      expect(wrapper.find("a").exists()).toBe(false);
      expect(document.activeElement).toBe(button.element);
    });

    it("runs its action from the control itself", async () => {
      const action = vi.fn();
      const wrapper = mountItem({ action, label: "Logout" });

      // Where Enter and Space on a focused button arrive, and the reason the
      // handler sits on the button rather than on the row around it.
      await wrapper.get("button").trigger("click");

      expect(action).toHaveBeenCalledOnce();
    });

    // Nothing in the navigation is in a form today, and a bare button would
    // submit the first one it ever ends up in.
    it("is not a submit button", () => {
      const wrapper = mountItem({ action: vi.fn(), label: "Logout" });

      expect(wrapper.get("button").attributes("type")).toBe("button");
    });
  });

  describe("the favorite star", () => {
    const navigate = vi.fn();

    // The real link needs a router; the row only ever asks it for the href and
    // the function that follows it.
    const RouterLink = defineComponent({
      props: { to: { type: [Object, String], required: true } },
      setup(_, { slots }) {
        return () => slots.default?.({ href: "/trade-routes", navigate });
      },
    });

    const mountLink = (props: Record<string, unknown>) =>
      mount(NavItem, {
        props: {
          to: { name: "trade-routes" },
          label: "Trade Routes",
          ...props,
        },
        global: {
          directives: { tooltip: {} },
          components: { RouterLink },
        },
      });

    beforeEach(() => {
      navigate.mockReset();
      useNavStore().slim = false;
    });

    it("is absent from a row that cannot be pinned", () => {
      const wrapper = mountLink({});

      expect(wrapper.find(".nav-item__favorite").exists()).toBe(false);
    });

    it("says whether the page is pinned", () => {
      const wrapper = mountLink({ pinnable: true, favorite: true });

      expect(
        wrapper.get(".nav-item__favorite").attributes("aria-pressed"),
      ).toBe("true");
    });

    // The star sits inside the row, which follows the link on click.
    it("pins without opening the page", async () => {
      const wrapper = mountLink({ pinnable: true, favorite: false });

      await wrapper.get(".nav-item__favorite").trigger("click");

      expect(wrapper.emitted("toggleFavorite")).toHaveLength(1);
      expect(navigate).not.toHaveBeenCalled();
    });

    // A collapsed rail is icons only; there is no room for a second target.
    it("is left off the collapsed rail", () => {
      useNavStore().slim = true;

      const wrapper = mountLink({ pinnable: true, favorite: false });

      expect(wrapper.find(".nav-item__favorite").exists()).toBe(false);
    });
  });
});
