import { HardpointCategoryEnum } from "@/services/fyApi";
import { type Glyph } from "@/shared/components/DuotoneGlyph/glyph";
import { HARDPOINT_GLYPHS } from "@/frontend/components/Models/Hardpoints/CategoryIcon/glyphs";

// A component's own category is one word where a hardpoint slot names the four
// places a thruster sits, so `thrusters` has no icon of its own. The main
// thruster's stands for the group, as it does in the hardpoint list.
const ALIASES: Record<string, HardpointCategoryEnum> = {
  thrusters: HardpointCategoryEnum.MAIN_THRUSTERS,
};

const isCategory = (category: string): category is HardpointCategoryEnum =>
  category in HARDPOINT_GLYPHS;

// A category a patch introduces before the enum knows it gets the unknown
// glyph, which says exactly that rather than leaving a gap.
export const categoryIcon = (category?: string | null): Glyph | undefined => {
  if (!category) return undefined;

  const key = ALIASES[category] ?? category;

  return HARDPOINT_GLYPHS[
    isCategory(key) ? key : HardpointCategoryEnum.UNKNOWN
  ];
};
