import Component from "@/frontend/components/Models/Panel/index.vue";
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";

const model: Model = {
  name: "Enterprise",
  slug: "enterprise",
  media: {
    storeImage: {
      source: "TestImage",
      small: "TestImage",
      medium: "TestImage",
      large: "TestImage",
    },
  },
  manufacturer: {
    id: "1",
    code: "FED",
    name: "Utopia Planitia",
  },
  shipRole: {
    name: "Exporation Cruiser",
  },
};

describe("BasePanel", () => {
  it("renders", () => {
    const wrapper = mount(Component, {
      props: { model },
    });
    expect(wrapper.exists()).toBe(true);
  });
});
