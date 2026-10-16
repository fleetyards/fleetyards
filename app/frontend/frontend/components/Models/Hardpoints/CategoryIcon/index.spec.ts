import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { HardpointCategoryEnum } from "@/services/fyApi";
import { HARDPOINT_GLYPHS } from "./glyphs";
import { categoryIcon } from "../categoryIcon";
import Component from "./index.vue";

describe("HardpointCategoryIcon", () => {
  it.each(Object.values(HardpointCategoryEnum))(
    "has a glyph of its own for %s",
    (category) => {
      expect(HARDPOINT_GLYPHS[category]?.primary).toBeTruthy();
    },
  );

  it("draws every category differently", () => {
    const drawings = Object.values(HARDPOINT_GLYPHS).map(
      (glyph) => `${glyph.secondary}|${glyph.primary}`,
    );

    expect(new Set(drawings).size).toBe(drawings.length);
  });

  it("draws the main thruster for a component's thrusters category", () => {
    expect(categoryIcon("thrusters")).toBe(
      HARDPOINT_GLYPHS[HardpointCategoryEnum.MAIN_THRUSTERS],
    );
  });

  it("draws the unknown glyph for a category the enum does not know", () => {
    expect(categoryIcon("warp_coils")).toBe(
      HARDPOINT_GLYPHS[HardpointCategoryEnum.UNKNOWN],
    );
  });

  it("does not mistake an inherited key for a category", () => {
    expect(categoryIcon("constructor")).toBe(
      HARDPOINT_GLYPHS[HardpointCategoryEnum.UNKNOWN],
    );
  });

  it("renders the glyph", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { category: "radar" },
    });

    expect(wrapper.find(".duotone-glyph").exists()).toBe(true);
  });

  it("keeps an empty box without a category", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { category: null },
    });

    expect(wrapper.find(".duotone-glyph").exists()).toBe(false);
    expect(wrapper.find(".hardpoint-category-icon").exists()).toBe(true);
  });
});
