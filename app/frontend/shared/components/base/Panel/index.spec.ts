import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

describe("BasePanel", () => {
  it("renders", () => {
    const wrapper = mount(Component);
    expect(wrapper.exists()).toBe(true);
  });

  it("runs its bottom cap while loading", () => {
    const wrapper = mount(Component, { props: { loading: true } });

    expect(wrapper.classes()).toContain("panel--loading");
  });

  it("is not loading by default", () => {
    const wrapper = mount(Component);

    expect(wrapper.classes()).not.toContain("panel--loading");
  });
});
