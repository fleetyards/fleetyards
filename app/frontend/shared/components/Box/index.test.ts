import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

describe("BaseBox", () => {
  it("renders", () => {
    const wrapper = mount(Component);
    expect(wrapper.exists()).toBe(true);
  });

  it("renders large box", () => {
    const wrapper = mount(Component, {
      props: { large: true },
    });
    expect(wrapper.vm.$el.className).toBe("box-large box");
  });
});
