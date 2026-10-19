import {
  byStat,
  NEUTRAL_QUALITY,
  segmentsOf,
  valueAt,
} from "@/frontend/composables/useQualityRamp";
import {
  type BlueprintCostSlot,
  type Component,
  type Equipment,
} from "@/services/fyApi";

// The figures a recipe's modifiers move, by the modifier's property key -- the
// same pairing `BlueprintStatBases` makes on the API. A key without a figure
// here moves something the catalogue does not hold, and is left alone.
const COMPONENT_FIELDS: Record<string, string> = {
  gpp_itemresource_coolantgeneration: "coolingRate",
  gpp_shield_maxhealth: "maxHealth",
  gpp_radar_minaimassistdistance: "aimAssistMin",
  gpp_radar_maxaimassistdistance: "aimAssistRange",
  gpp_quantum_speed: "driveSpeed",
  gpp_weapon_tractor_force: "maxForce",
  gpp_weapon_tractor_maxdist: "maxDistance",
  gpp_weapon_tractor_maxvolume: "maxVolume",
};

const EQUIPMENT_FIELDS: Record<string, keyof Equipment> = {
  gpp_armor_damagemitigation: "damageReduction",
  gpp_weapon_firerate: "rateOfFire",
  gpp_armor_radiationdissipation: "radiationScrubRate",
};

/**
 * What each stat is multiplied by at these grades. Every ramp is 1.0x at the
 * neutral grade, which is the figure the catalogue holds, so the catalogue's
 * value times this is the crafted value. Two slots moving one stat compose by
 * multiplying, as the recipe preview composes them.
 */
export const craftedFactors = (
  slots: BlueprintCostSlot[],
  qualities: Record<string, number | undefined>,
) => {
  const factors = new Map<string, number>();

  slots.forEach((slot) => {
    const at = qualities[slot.position] ?? NEUTRAL_QUALITY;

    byStat(slot.modifiers || []).forEach((group, key) => {
      const segments = segmentsOf(group);
      if (!segments.length) return;

      factors.set(key, (factors.get(key) ?? 1) * valueAt(segments, at));
    });
  });

  return factors;
};

const scaled = (value: unknown, factor: number) =>
  typeof value === "number" ? value * factor : value;

// The component as it came out of the recipe: the catalogue's record with the
// figures the grades move scaled. Everything else is the record's own.
export const craftComponent = (
  component: Component,
  factors: Map<string, number>,
): Component => {
  const typeData = { ...(component.typeData as Record<string, unknown>) };

  factors.forEach((factor, key) => {
    // A weapon's damage is split across the types it deals.
    if (key === "gpp_weapon_damage") {
      const perShot = typeData.damagePerShot as
        Record<string, unknown> | undefined;

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

    const field = COMPONENT_FIELDS[key];
    if (field) typeData[field] = scaled(typeData[field], factor);
  });

  // Integrity: how much damage the part takes, kept with its durability
  // rather than in the type's own figures.
  const integrity = factors.get("gpp_health_maxhealth");
  const durability =
    integrity && component.durability
      ? {
          ...component.durability,
          health: scaled(component.durability.health, integrity) as
            number | undefined,
        }
      : component.durability;

  return { ...component, typeData, durability } as Component;
};

export const craftEquipment = (
  equipment: Equipment,
  factors: Map<string, number>,
): Equipment => {
  const crafted = { ...equipment } as unknown as Record<string, unknown>;

  factors.forEach((factor, key) => {
    const field = EQUIPMENT_FIELDS[key];
    if (field) crafted[field] = scaled(crafted[field], factor);
  });

  return crafted as unknown as Equipment;
};
