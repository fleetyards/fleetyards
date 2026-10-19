import {
  amountAt,
  byStat,
  isAdditive,
  segmentsOf,
  valueAt,
} from "@/frontend/composables/useQualityRamp";
import type {
  BlueprintCostSlot,
  Component,
  Equipment,
  LoadoutComponentRef,
} from "@/services/fyApi";

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

export type CraftedChanges = Map<string, CraftedChange>;

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

// A part's own figures as the changes leave them. Everything the changes do
// not name is the catalogue's.
const craftedTypeData = (
  typeData: Record<string, unknown>,
  changes: CraftedChanges,
) => {
  const crafted: Record<string, unknown> = { ...typeData };

  changes.forEach((change, key) => {
    if (key === WEAPON_DAMAGE) {
      const perShot = crafted.damagePerShot;
      if (perShot && typeof perShot === "object") {
        crafted.damagePerShot = Object.fromEntries(
          Object.entries(perShot).map(([type, value]) => [
            type,
            changed(value, change),
          ]),
        );
      }
      return;
    }

    const field = CRAFTED_COMPONENT_FIELDS[key];
    if (field && field in crafted) {
      crafted[field] = changed(crafted[field], change);
    }
  });

  return crafted;
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

  return {
    ...component,
    typeData: craftedTypeData(
      component.typeData as Record<string, unknown>,
      craftedFactors(slots, qualityFor),
    ) as LoadoutComponentRef["typeData"],
  };
};

// How much damage a part takes before it fails, kept with its durability
// rather than with its type's own figures.
const INTEGRITY = "gpp_health_maxhealth";

/**
 * A catalogue component as crafted -- its integrity included, which a loadout
 * socket's slimmer record does not carry.
 */
export const craftedCatalogueComponent = (
  component: Component,
  changes: CraftedChanges,
): Component => {
  const integrity = changes.get(INTEGRITY);
  const durability =
    integrity && component.durability
      ? {
          ...component.durability,
          health: changed(component.durability.health, integrity) as
            number | undefined,
        }
      : component.durability;

  return {
    ...component,
    typeData: craftedTypeData(
      (component.typeData ?? {}) as Record<string, unknown>,
      changes,
    ) as Component["typeData"],
    durability,
  };
};

// The equipment figures a recipe moves, as `BlueprintStatBases::EQUIPMENT`
// pairs them on the server.
const CRAFTED_EQUIPMENT_FIELDS: Record<string, keyof Equipment> = {
  gpp_armor_damagemitigation: "damageReduction",
  gpp_weapon_firerate: "rateOfFire",
  gpp_armor_radiationdissipation: "radiationScrubRate",
};

// Armour states its band as one string -- "-75 / 98 °C" -- and some leave the
// degree sign off; the pattern `BlueprintStatBases` reads it with.
const TEMPERATURE = /^\s*(-?[\d.]+)\s*\/\s*(-?[\d.]+)\s*°?\s*C\s*$/;
const TEMPERATURE_KEY = "gpp_armor_temperature";

const roundedDegrees = (value: number) => Math.round(value * 10) / 10;

const craftedTemperature = (
  rating: string | null | undefined,
  changes: CraftedChanges,
) => {
  const match = rating?.match(TEMPERATURE);
  if (!match) return rating;

  let min = Number(match[1]);
  let max = Number(match[2]);
  let moved = false;

  changes.forEach((change, key) => {
    if (!key.startsWith(TEMPERATURE_KEY)) return;

    moved = true;
    if (key.endsWith("min")) {
      min = changed(min, change) as number;
    } else {
      max = changed(max, change) as number;
    }
  });

  return moved ? `${roundedDegrees(min)} / ${roundedDegrees(max)} °C` : rating;
};

/** A piece of equipment as crafted, its temperature band included. */
export const craftedEquipment = (
  equipment: Equipment,
  changes: CraftedChanges,
): Equipment => {
  const crafted = { ...equipment } as unknown as Record<string, unknown>;

  changes.forEach((change, key) => {
    const field = CRAFTED_EQUIPMENT_FIELDS[key];
    if (field) crafted[field] = changed(crafted[field], change);
  });

  crafted.temperatureRating = craftedTemperature(
    equipment.temperatureRating,
    changes,
  );

  return crafted as unknown as Equipment;
};
