import { type ComponentWeaponDamage } from "@/services/fyApi";

// An attachment states multipliers; a reader wants the change one makes, so
// 0.8 reads as -20 and 1.2 as +20, to one decimal.
export const multiplierChange = (multiplier?: number | null) =>
  multiplier == null ? undefined : Math.round((multiplier - 1) * 1000) / 10;

// A change carries its sign; a rise its plus.
export const signed = (text: string, value: number) =>
  value > 0 ? `+${text}` : text;

// What a hit deals across every damage type it carries.
export const damageTotal = (damage?: ComponentWeaponDamage | null) => {
  if (!damage) return undefined;

  const sum = Object.values(damage).reduce<number>(
    (acc, value) => acc + (value ?? 0),
    0,
  );

  return sum || undefined;
};

// A raw game name -- "blade_slash", "TractorBeam" -- as words, for a value a
// new build introduces before anyone writes a label for it.
export const humanizeGameName = (name?: string | null) => {
  const words = name
    ?.replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/_/g, " ")
    .trim();

  return words ? words.charAt(0).toUpperCase() + words.slice(1) : undefined;
};
