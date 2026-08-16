import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import { setActivePinia, createPinia } from "pinia";

describe("NavItemInner", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  const mount = (props: Record<string, unknown>) =>
    mountWithDefaults<typeof Component>(Component, {
      props: { label: "Notifications", icon: "fa-duotone fa-bell", ...props },
    });

  it("hides the badge at zero", async () => {
    const wrapper = await mount({ badge: 0 });

    expect(wrapper.find(".nav-item-badge").exists()).toBe(false);
  });

  it("renders the badge count", async () => {
    const wrapper = await mount({ badge: 3 });

    expect(wrapper.find(".nav-item-badge").text()).toBe("3");
  });

  it("caps the badge at 99+", async () => {
    const wrapper = await mount({ badge: 250 });

    expect(wrapper.find(".nav-item-badge").text()).toBe("99+");
  });

  it("moves the badge onto the icon when slim", async () => {
    const wrapper = await mount({ badge: 3, slim: true });

    expect(wrapper.find(".nav-item-badge--dot").exists()).toBe(true);
  });
});
