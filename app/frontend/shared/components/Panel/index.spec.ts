import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import Component from "@/shared/components/Panel/index.vue";

describe("BasePanel", () => {
  it("renders", () => {
    const wrapper = mount(Component);
    expect(wrapper.exists()).toBe(true);
  });
});
