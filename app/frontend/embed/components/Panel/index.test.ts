import Component from "@/frontend/core/components/Panel/index.vue";
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";

describe("EmbedPanel", () => {
  it("renders", () => {
    const wrapper = mount(Component);
    expect(wrapper.exists()).toBe(true);
  });
});
