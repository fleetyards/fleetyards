import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import Component from "@/docs/components/core/AppFooter/index.vue";

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
