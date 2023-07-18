import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import Component from "@/docs/components/core/SmallLoader/index.vue";

describe("SmallLoader", () => {
  it("renders", () => {
    const wrapper = mount(Component);
    expect(wrapper.exists()).toBe(true);
  });

  it("does not render Smallloader default", () => {
    const wrapper = mount(Component);
    expect(wrapper.find("span").exists()).toBe(false);
  });

  it("renders Smallloader", () => {
    const wrapper = mount(Component, { props: { loading: true } });
    expect(wrapper.find("span").exists()).toBe(true);
  });
});
