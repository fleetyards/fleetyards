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
  gpp_itemresource_powergeneration: "powerBase",
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

// What the grades do to one stat. Most ramps scale it; an additive one -- a
// power plant's pips -- adds a whole amount to it instead, which multiplying
// would turn 28 into -28 rather than 27.
export type CraftedEffect = { additive: boolean; value: number };

const ADDITIVE_RAMP = "linear_integer_additive";

/**
 * What the grades do to each stat. Every scaling ramp is 1.0x at the neutral
 * grade, which is the figure the catalogue holds, so the catalogue's value
 * times this is the crafted value; an additive ramp is 0 there. Two slots
 * moving one stat compose: factors multiply, as the recipe preview composes
 * them, and amounts add, each rounded to the whole amount the game adds.
 */
export const craftedFactors = (
  slots: BlueprintCostSlot[],
  qualities: Record<string, number | undefined>,
) => {
  const effects = new Map<string, CraftedEffect>();

  slots.forEach((slot) => {
    const at = qualities[slot.position] ?? NEUTRAL_QUALITY;

    byStat(slot.modifiers || []).forEach((group, key) => {
      const segments = segmentsOf(group);
      if (!segments.length) return;

      const additive = group.some(
        (modifier) => modifier.ramp === ADDITIVE_RAMP,
      );
      const value = valueAt(segments, at);
      const held = effects.get(key);

      effects.set(
        key,
        additive
          ? { additive, value: (held?.value ?? 0) + Math.round(value) }
          : { additive, value: (held?.value ?? 1) * value },
      );
    });
  });

  return effects;
};

const applied = (value: unknown, effect: CraftedEffect) => {
  if (typeof value !== "number") return value;

  return effect.additive ? value + effect.value : value * effect.value;
};

// The component as it came out of the recipe: the catalogue's record with the
// figures the grades move scaled. Everything else is the record's own.
export const craftComponent = (
  component: Component,
  factors: Map<string, CraftedEffect>,
): Component => {
  const typeData = { ...(component.typeData as Record<string, unknown>) };

  factors.forEach((effect, key) => {
    // A weapon's damage is split across the types it deals.
    if (key === "gpp_weapon_damage") {
      const perShot = typeData.damagePerShot as
        Record<string, unknown> | undefined;

      if (perShot && typeof perShot === "object") {
        typeData.damagePerShot = Object.fromEntries(
          Object.entries(perShot).map(([type, value]) => [
            type,
            applied(value, effect),
          ]),
        );
      }

      return;
    }

    const field = COMPONENT_FIELDS[key];
    if (field) typeData[field] = applied(typeData[field], effect);
  });

  // Integrity: how much damage the part takes, kept with its durability
  // rather than in the type's own figures.
  const integrity = factors.get("gpp_health_maxhealth");
  const durability =
    integrity && component.durability
      ? {
          ...component.durability,
          health: applied(component.durability.health, integrity) as
            number | undefined,
        }
      : component.durability;

  return { ...component, typeData, durability } as Component;
};

export const craftEquipment = (
  equipment: Equipment,
  factors: Map<string, CraftedEffect>,
): Equipment => {
  const crafted = { ...equipment } as unknown as Record<string, unknown>;

  factors.forEach((effect, key) => {
    const field = EQUIPMENT_FIELDS[key];
    if (field) crafted[field] = applied(crafted[field], effect);
  });

  crafted.temperatureRating = craftedTemperature(
    equipment.temperatureRating,
    factors,
  );

  return crafted as unknown as Equipment;
};

// Armour states its band as one string -- "-75 / 98 °C" -- rather than two
// figures, and some leave the degree sign off. The same pattern
// `BlueprintStatBases` reads it with on the API.
const TEMPERATURE = /^\s*(-?[\d.]+)\s*\/\s*(-?[\d.]+)\s*°?\s*C\s*$/;
const TEMPERATURE_KEY = "gpp_armor_temperature";

const roundedDegrees = (value: number) => Math.round(value * 10) / 10;

const craftedTemperature = (
  rating: string | null | undefined,
  factors: Map<string, CraftedEffect>,
) => {
  const match = rating?.match(TEMPERATURE);
  if (!match) return rating;

  let min = Number(match[1]);
  let max = Number(match[2]);
  let moved = false;

  factors.forEach((effect, key) => {
    if (!key.startsWith(TEMPERATURE_KEY)) return;

    moved = true;
    if (key.endsWith("min")) {
      min = applied(min, effect) as number;
    } else {
      max = applied(max, effect) as number;
    }
  });

  return moved ? `${roundedDegrees(min)} / ${roundedDegrees(max)} °C` : rating;
};
