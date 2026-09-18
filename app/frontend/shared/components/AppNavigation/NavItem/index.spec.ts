import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount } from "@vue/test-utils";
import { setActivePinia, createPinia } from "pinia";

// The item reads the route to mark the open page. The action branch never does,
// but the setup runs whichever branch renders.
vi.mock("vue-router", () => ({
  useRoute: () => ({ name: "home" }),
}));

import NavItem from "./index.vue";

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
});
