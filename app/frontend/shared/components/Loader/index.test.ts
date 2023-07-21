import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import Component from "@/frontend/core/components/Loader/index.vue";

describe("BaseLoader", () => {
  it("renders", () => {
    const wrapper = mount(Component);
    expect(wrapper.exists()).toBe(true);
  });

  it("does not render loader on default", () => {
    const wrapper = mount(Component);
    expect(wrapper.find("div").exists()).toBe(false);
  });

  it("renders centered loader", () => {
    const wrapper = mount(Component, { propsData: { loading: true } });
    const mainElement = wrapper.find("div");

    expect(mainElement.exists()).toBe(true);
    expect(mainElement.classes("loader")).toBe(true);
    expect(wrapper.find(".loader").exists()).toBe(true);
  });
});
