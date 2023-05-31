import Component from "@/frontend/core/components/AppNavigation/index.vue";
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";

describe("AppNavigation", () => {
  it("renders", () => {
    const wrapper = mount(Component);
    expect(wrapper.exists()).toBe(true);
  });

  it("renders nothing without pagination info", () => {
    const wrapper = mount(Component);
    expect(wrapper.findAll("nav")).toHaveLength(1);
  });
});
