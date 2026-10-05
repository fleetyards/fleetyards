import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

describe("AppIcon", () => {
  it("renders a Font Awesome class as an icon element", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { icon: "fa-duotone fa-bell" },
    });

    expect(wrapper.find("i").classes()).toContain("fa-bell");
    expect(wrapper.find(".duotone-glyph").exists()).toBe(false);
  });

  it("draws a glyph", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { icon: { secondary: "<rect/>", primary: "<rect/>" } },
    });

    expect(wrapper.find(".duotone-glyph").exists()).toBe(true);
    expect(wrapper.find("i").exists()).toBe(false);
  });
});
