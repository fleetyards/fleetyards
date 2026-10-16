import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

describe("HardpointCategoryIcon", () => {
  it("renders a drawn icon", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { category: "radar" },
    });

    expect(wrapper.find("img").exists()).toBe(true);
  });

  it("renders a Font Awesome icon", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { category: "armor" },
    });

    expect(wrapper.find("i").classes()).toContain("fa-shield-halved");
  });

  it("keeps an empty slot rather than a broken image for a category without an icon", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { category: "scanners" },
    });

    expect(wrapper.find("img").exists()).toBe(false);
    expect(wrapper.find(".hardpoint-category-icon").exists()).toBe(true);
  });
});
