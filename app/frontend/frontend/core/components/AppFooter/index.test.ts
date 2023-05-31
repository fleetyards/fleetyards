import Component from "@/frontend/core/components/Box/index.vue";
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";

describe("AppFooter", () => {
  it("renders", () => {
    const wrapper = mount(Component);
    expect(wrapper.exists()).toBe(true);
  });

  it("renders all links", () => {
    const wrapper = mount(Component);
    expect(wrapper.findAll("a")).toHaveLength(6);
  });
});
