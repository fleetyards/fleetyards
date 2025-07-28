import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

const item = {
  name: "Enterprise",
  description: "",
  storeImage: "TestImage",
  storeImageMedium: "TestImage",
};

describe("TeaserPanel", async () => {
  it("renders", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: { item },
    });
    expect(wrapper.exists()).toBe(true);
  });
});
