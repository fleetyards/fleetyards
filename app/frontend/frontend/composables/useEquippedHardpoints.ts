import { computed, toValue, type MaybeRefOrGetter } from "vue";
import { type Hardpoint, type ModelModule } from "@/services/fyApi";

export type EquippedModules = Record<string, ModelModule | null>;

// The key a module slot is chosen under, matching how the slot row keys its own
// selection.
export function slotId(hardpoint: Hardpoint): string {
  return hardpoint.groupKey || hardpoint.id;
}

// Every metric on a ship page walks the hardpoint tree, so a module the reader
// picked has to hang off the slot holding it -- otherwise nothing but the cargo
// card notices the choice, and swapping a torpedo bay for a cargo bay leaves
// the combat figures answering for a ship nobody is looking at.
//
// Grafted onto the slot rather than appended to the list: a slot holds whatever
// module is in it, so replacing its contents is what keeps a default module
// from being counted alongside the one that replaced it. Ships currently ship
// their bays unladen, which is why appending has looked the same so far.
export function graftEquippedModules(
  hardpoints: Hardpoint[] | undefined,
  equipped: EquippedModules | undefined,
): Hardpoint[] {
  const base = hardpoints ?? [];

  if (!equipped || !Object.keys(equipped).length) {
    return base;
  }

  return base.map((hardpoint) => {
    const module = equipped[slotId(hardpoint)];

    if (!module) {
      return hardpoint;
    }

    return { ...hardpoint, hardpoints: module.hardpoints ?? [] };
  });
}

export function useEquippedHardpoints(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
  equipped: MaybeRefOrGetter<EquippedModules | undefined>,
) {
  return computed(() =>
    graftEquippedModules(toValue(hardpoints), toValue(equipped)),
  );
}
