import { type Component } from "@/services/fyApi";

// The eight figures inside `type_data` the server can sort on, each with the
// label the site already uses for it. Every one belongs to exactly one category
// -- shield HP to shieldgenerator, cooling rate to cooler -- so the label is
// that category's own rather than a new vocabulary, and all eight resolve in
// all seven locales.
//
// `sort` is the name `Component::ALLOWED_SORTING_PARAMS` whitelists; `field` is
// what the payload calls it, camelised from the snake_case key the column
// stores.
export const METRIC_FIELDS = [
  {
    field: "maxHealth",
    sort: "maxHealth",
    labelKey: "labels.hardpoint.shields.hp",
  },
  {
    field: "maxRegen",
    sort: "maxRegen",
    labelKey: "labels.hardpoint.shields.regen",
  },
  { field: "health", sort: "health", labelKey: "labels.hardpoint.armor.hp" },
  {
    field: "powerBase",
    sort: "powerBase",
    labelKey: "labels.hardpoint.powerPlants.output",
  },
  {
    field: "coolingRate",
    sort: "coolingRate",
    labelKey: "labels.hardpoint.coolers.coolingRate",
  },
  {
    field: "driveSpeed",
    sort: "driveSpeed",
    labelKey: "labels.hardpoint.quantumDrives.speed",
  },
  {
    field: "jumpRange",
    sort: "jumpRange",
    labelKey: "labels.hardpoint.quantumDrives.range",
  },
  {
    field: "thrustCapacity",
    sort: "thrustCapacity",
    labelKey: "labels.hardpoint.thrusters.thrust",
  },
] as const;

export const metricValue = (record: Component, field: string) =>
  (record.typeData as Record<string, unknown> | undefined)?.[field];
