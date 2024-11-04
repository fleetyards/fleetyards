import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

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
