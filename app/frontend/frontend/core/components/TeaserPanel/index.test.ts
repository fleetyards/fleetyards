import Component from "@/frontend/core/components/TeaserPanel/index.vue";
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";

const item = {
  name: "Enterprise",
  description: "",
  storeImage: "TestImage",
  storeImageMedium: "TestImage",
};

describe("TeaserPanel", () => {
  it("renders", () => {
    const wrapper = mount(Component, {
      props: { item },
    });
    expect(wrapper.exists()).toBe(true);
  });
});
