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

describe("NavItem", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
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
