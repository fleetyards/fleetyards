import type { ScDataPatchSummaryShipChangesItemFieldsItem } from "@/services/fyApi";

export type PatchField = ScDataPatchSummaryShipChangesItemFieldsItem;

// The unit `toNumber` formats a fact with. A fact not listed is a plain count.
export const FIELD_UNITS: Record<string, string> = {
  mass: "weight",
  personal_inventory: "cargo",
  main_acceleration: "acceleration",
  retro_acceleration: "acceleration",
  scm_speed: "speed",
  scm_speed_boosted: "speed",
  reverse_speed_boosted: "speed",
  max_speed: "speed",
  pitch: "rotation",
  pitch_boosted: "rotation",
  yaw: "rotation",
  yaw_boosted: "rotation",
  roll: "rotation",
  roll_boosted: "rotation",
  ground_max_speed: "speed",
  ground_reverse_speed: "speed",
  ground_acceleration: "acceleration",
  ground_deceleration: "acceleration",
  rate_of_fire: "rateOfFire",
  range: "distance",
  damage_reduction: "percent",
};

export const fieldKey = (field: string) =>
  (field.split(".").pop() || field).replace(/_(\w)/g, (_, c: string) =>
    c.toUpperCase(),
  );

// How far a fact moved relative to where it was, as a signed fraction, or
// undefined when either side is not a number.
export const movement = (field: PatchField) => {
  if (typeof field.from !== "number" || typeof field.to !== "number") {
    return undefined;
  }

  if (field.from === 0) {
    return undefined;
  }

  return (field.to - field.from) / Math.abs(field.from);
};

// The facts of one record, the ones that moved most first.
export const byMovement = (fields: PatchField[]) =>
  [...fields].sort(
    (a, b) => Math.abs(movement(b) ?? 0) - Math.abs(movement(a) ?? 0),
  );
