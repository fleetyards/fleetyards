import { type Hardpoint, HardpointCategoryEnum } from "@/services/fyApi";

// Cosmetic geometry (turret shells, weapon shrouds, wingtip covers) sits on
// child ports as nameless `Misc`/`AttachedPart` items that stay uncategorised —
// they'd render as bare "TBD" rows, unlike a genuinely empty slot, which keeps
// its category.
const isCosmetic = (hp: Hardpoint) =>
  hp.category === HardpointCategoryEnum.UNKNOWN && !hp.component?.name;

// What sits inside a hardpoint's part, as its row lists it below itself.
export const partContents = (hardpoint: Hardpoint): Hardpoint[] => {
  if (hardpoint.hardpoints?.length) {
    return hardpoint.hardpoints.filter((hp) => !isCosmetic(hp));
  }

  if (
    hardpoint.component?.hardpoints?.length &&
    hardpoint.component.hardpoints[0].component
  ) {
    return hardpoint.component.hardpoints.filter((hp) => !isCosmetic(hp));
  }

  return [];
};
