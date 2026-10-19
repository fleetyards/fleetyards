import {
  amountAt,
  byStat,
  isAdditive,
  segmentsOf,
  valueAt,
} from "@/frontend/composables/useQualityRamp";
import type { BlueprintCostSlot, LoadoutComponentRef } from "@/services/fyApi";

/**
 * The part figure each crafted stat scales, by the stat's property key.
 * Mirrors `BlueprintStatBases::COMPONENT` on the server, which resolves the
 * blueprint page's base values from the same fields; a key with no figure in
 * the catalogue -- component health, quantum fuel burn -- moves nothing here.
 */
export const CRAFTED_COMPONENT_FIELDS: Record<string, string> = {
  gpp_itemresource_coolantgeneration: "coolingRate",
  gpp_itemresource_powergeneration: "powerBase",
  gpp_shield_maxhealth: "maxHealth",
  gpp_radar_minaimassistdistance: "aimAssistMin",
  gpp_radar_maxaimassistdistance: "aimAssistRange",
  gpp_quantum_speed: "driveSpeed",
  gpp_weapon_tractor_force: "maxForce",
  gpp_weapon_tractor_maxdist: "maxDistance",
  gpp_weapon_tractor_maxvolume: "maxVolume",
};

// A weapon's damage is split across the types it deals; the factor applies to
// each of them alike.
const WEAPON_DAMAGE = "gpp_weapon_damage";

export type CraftedQualities = Record<number, number>;

// How a part was crafted: the recipe, and the material quality in each of its
// slots by position. A slot left out was filled at the neutral grade.
export interface CraftedPart {
  blueprintId: string;
  blueprintSlug: string;
  qualities: CraftedQualities;
}

export type CraftedChange = { additive: boolean; value: number };

/**
 * What every stat ends up at for the qualities chosen, by property key: a
 * factor, or for an additive stat -- a power plant's pips -- an amount added.
 *
 * Two slots moving one stat are independent factors on it and so multiply, as
 * the blueprint page composes them; amounts add up.
 */
export const craftedFactors = (
  slots: BlueprintCostSlot[],
  qualityFor: (position: number) => number,
) => {
  const changes = new Map<string, CraftedChange>();

  slots.forEach((slot) => {
    byStat(slot.modifiers || []).forEach((group, key) => {
      const segments = segmentsOf(group);
      if (!segments.length) return;

      const at = qualityFor(slot.position);
      const additive = isAdditive(group);
      const held = changes.get(key)?.value;

      changes.set(key, {
        additive,
        value: additive
          ? (held ?? 0) + amountAt(segments, at)
          : (held ?? 1) * valueAt(segments, at),
      });
    });
  });

  return changes;
};

const changed = (value: unknown, change: CraftedChange) => {
  if (typeof value !== "number") return value;

  return change.additive ? value + change.value : value * change.value;
};

/**
 * The part as crafted: its figures moved by the recipe's factors at the
 * qualities chosen. The catalogue's figure is the neutral grade's, so a part
 * crafted at 500 in every slot reads exactly as the catalogue's.
 */
export const craftedComponent = (
  component: LoadoutComponentRef,
  slots: BlueprintCostSlot[],
  qualityFor: (position: number) => number,
): LoadoutComponentRef => {
  if (!component.typeData) return component;

  const typeData: Record<string, unknown> = { ...component.typeData };

  craftedFactors(slots, qualityFor).forEach((change, key) => {
    if (key === WEAPON_DAMAGE) {
      const perShot = typeData.damagePerShot;
      if (perShot && typeof perShot === "object") {
        typeData.damagePerShot = Object.fromEntries(
          Object.entries(perShot).map(([type, value]) => [
            type,
            changed(value, change),
          ]),
        );
      }
      return;
    }

    const field = CRAFTED_COMPONENT_FIELDS[key];
    if (field && field in typeData) {
      typeData[field] = changed(typeData[field], change);
    }
  });

  return {
    ...component,
    typeData: typeData as LoadoutComponentRef["typeData"],
  };
};
