import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import Component from "@/frontend/core/components/Panel/index.vue";

describe("EmbedPanel", () => {
  it("renders", () => {
    const wrapper = mount(Component);
    expect(wrapper.exists()).toBe(true);
  });
});
