import {
  byStat,
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

/**
 * The factor every stat ends up at for the qualities chosen, by property key.
 *
 * Two slots moving one stat are independent factors on it and so multiply, as
 * the blueprint page composes them.
 */
export const craftedFactors = (
  slots: BlueprintCostSlot[],
  qualityFor: (position: number) => number,
) => {
  const factors = new Map<string, number>();

  slots.forEach((slot) => {
    byStat(slot.modifiers || []).forEach((group, key) => {
      const segments = segmentsOf(group);
      if (!segments.length) return;

      factors.set(
        key,
        (factors.get(key) ?? 1) * valueAt(segments, qualityFor(slot.position)),
      );
    });
  });

  return factors;
};

const scaled = (value: unknown, factor: number) =>
  typeof value === "number" ? value * factor : value;

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

  craftedFactors(slots, qualityFor).forEach((factor, key) => {
    if (key === WEAPON_DAMAGE) {
      const perShot = typeData.damagePerShot;
      if (perShot && typeof perShot === "object") {
        typeData.damagePerShot = Object.fromEntries(
          Object.entries(perShot).map(([type, value]) => [
            type,
            scaled(value, factor),
          ]),
        );
      }
      return;
    }

    const field = CRAFTED_COMPONENT_FIELDS[key];
    if (field && field in typeData) {
      typeData[field] = scaled(typeData[field], factor);
    }
  });

  return {
    ...component,
    typeData: typeData as LoadoutComponentRef["typeData"],
  };
};
