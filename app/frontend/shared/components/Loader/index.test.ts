import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

describe("BaseLoader", () => {
  it("renders", () => {
    const wrapper = mount(Component);
    expect(wrapper.exists()).toBe(true);
  });

  it("does not render loader on default", () => {
    const wrapper = mount(Component);
    expect(wrapper.find("div").exists()).toBe(false);
  });

  it("waits before it shows, unless it is immediate", () => {
    const transitionName = (immediate: boolean) =>
      mount(Component, { props: { loading: true, immediate } })
        .findComponent({ name: "Transition" })
        .props("name");

    expect(transitionName(false)).toBe("fade");
    expect(transitionName(true)).toBe("fade-quick");
  });

  it("renders centered loader", () => {
    const wrapper = mount(Component, { propsData: { loading: true } });
    const mainElement = wrapper.find("div");

    expect(mainElement.exists()).toBe(true);
    expect(mainElement.classes("loader")).toBe(true);
    expect(wrapper.find(".loader").exists()).toBe(true);
  });
});
