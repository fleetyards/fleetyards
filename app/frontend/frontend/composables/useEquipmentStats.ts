import { EquipmentTypeEnum, type Equipment } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";

export type EquipmentStatKey =
  | "alphaDamage"
  | "dps"
  | "damageReduction"
  | "temperatureRating"
  | "radiationProtection"
  | "radiationScrubRate"
  | "gForceTolerance"
  | "carryingCapacity"
  | "magazineSize"
  | "rateOfFire"
  | "range"
  | "weaponClass"
  | "coreCompatibility"
  | "backpackCompatibility"
  | "volume";

// Which figures an item of each type leads with, then the rest in reading
// order. Armour, an undersuit and a rifle share almost nothing, so one fixed
// list would put a rate of fire on a jacket's page. The columns are flat on the
// payload, so each entry is a field to read rather than a shape to parse.
const VOCABULARY: Record<
  string,
  { primary: EquipmentStatKey[]; rest: EquipmentStatKey[] }
> = {
  [EquipmentTypeEnum.ARMOR]: {
    primary: ["damageReduction", "temperatureRating"],
    rest: [
      "radiationProtection",
      "radiationScrubRate",
      "carryingCapacity",
      "coreCompatibility",
      "backpackCompatibility",
      "volume",
    ],
  },
  [EquipmentTypeEnum.UNDERSUIT]: {
    primary: ["damageReduction", "gForceTolerance"],
    rest: [
      "temperatureRating",
      "radiationProtection",
      "radiationScrubRate",
      "carryingCapacity",
      "backpackCompatibility",
      "volume",
    ],
  },
  [EquipmentTypeEnum.CLOTHING]: {
    primary: ["carryingCapacity", "temperatureRating"],
    rest: [
      "damageReduction",
      "radiationProtection",
      "radiationScrubRate",
      "backpackCompatibility",
      "volume",
    ],
  },
  [EquipmentTypeEnum.WEAPON]: {
    primary: ["dps", "alphaDamage"],
    rest: ["rateOfFire", "range", "weaponClass", "magazineSize", "volume"],
  },
  [EquipmentTypeEnum.WEAPON_ATTACHMENT]: {
    primary: ["magazineSize"],
    rest: ["volume"],
  },
};

// Tools, medical items and hacking tools carry nothing but their volume.
const FALLBACK = {
  primary: [] as EquipmentStatKey[],
  rest: ["volume"] as EquipmentStatKey[],
};

export const equipmentVocabulary = (equipmentType?: string | null) =>
  VOCABULARY[equipmentType ?? ""] ?? FALLBACK;

type Figure = {
  value: (item: Equipment) => number | null | undefined;
  units?: string;
  // What the figure is shown in, where that differs from what it is stored in.
  shown?: (value: number) => number;
};

type Label = { label: (item: Equipment) => string | null | undefined };

// Where each stat is read from: a number, or a label the API already words.
const SOURCES: Record<EquipmentStatKey, Figure | Label> = {
  alphaDamage: { value: (item) => item.alphaDamage, units: "damage" },
  dps: { value: (item) => item.dps, units: "dps" },
  damageReduction: { value: (item) => item.damageReduction, units: "percent" },
  temperatureRating: { label: (item) => item.temperatureRating },
  radiationProtection: {
    value: (item) => item.radiationProtection,
    units: "rem",
  },
  radiationScrubRate: {
    value: (item) => item.radiationScrubRate,
    units: "remPerSecond",
  },
  gForceTolerance: { value: (item) => item.gForceTolerance },
  // One column, two meanings: the rounds a magazine holds, or what a suit or
  // jacket can carry. The parser keeps the figure and drops the unit, which is
  // not the same across apparel, so none is guessed here.
  carryingCapacity: { value: (item) => item.storage },
  magazineSize: { value: (item) => item.storage },
  rateOfFire: { value: (item) => item.rateOfFire, units: "rateOfFire" },
  range: { value: (item) => item.range, units: "distance" },
  weaponClass: { label: (item) => item.weaponClassLabel },
  coreCompatibility: { label: (item) => item.coreCompatibilityLabel },
  backpackCompatibility: { label: (item) => item.backpackCompatibilityLabel },
  // In µSCU, the unit an inventory grid counts in. As SCU a jacket is 0.0087,
  // which the stat formatter would round to nothing.
  volume: {
    value: (item) => item.volume,
    units: "microScu",
    shown: (value) => Math.round(value * 1_000_000),
  },
};

// One figure of an item, formatted, and the number behind it where there is one.
export const useEquipmentStatReader = () => {
  const { t, toNumber } = useI18n();

  // A figure the build does not carry is left out rather than printed as "N/A"
  // -- most items carry fewer than half of their type's list. A zero is a
  // figure, though, and `toNumber` would render it as "N/A", so it is formatted
  // here.
  const figure = (value: number | null | undefined, units = "") => {
    if (value == null) return undefined;
    if (value !== 0) return String(toNumber(value, units));

    return units ? t(`number.${units}`, { count: 0 }) : "0";
  };

  const raw = (item: Equipment, key: EquipmentStatKey): number | undefined => {
    const source = SOURCES[key];

    return "value" in source ? (source.value(item) ?? undefined) : undefined;
  };

  const read = (item: Equipment, key: EquipmentStatKey): string | undefined => {
    const source = SOURCES[key];
    if ("label" in source) return source.label(item) || undefined;

    const value = raw(item, key);

    return figure(
      value !== undefined && source.shown ? source.shown(value) : value,
      source.units,
    );
  };

  return { read, raw };
};

/**
 * Every figure the site holds for one equipment item, labelled and ordered for
 * its type, with the one or two it leads with marked `primary` -- the same
 * shape `useComponentStats` hands the metrics card and the row.
 */
export const useEquipmentStats = (
  equipment: MaybeRefOrGetter<Equipment | undefined>,
) => {
  const { t } = useI18n();
  const { read } = useEquipmentStatReader();

  return computed<HardpointStat[]>(() => {
    const item = toValue(equipment);
    if (!item) return [];

    const vocabulary = equipmentVocabulary(item.equipmentType);

    const build = (keys: EquipmentStatKey[], primary: boolean) =>
      keys.flatMap((key) => {
        const value = read(item, key);
        if (!value) return [];

        return [{ label: t(`labels.equipment.stats.${key}`), value, primary }];
      });

    // A weapon leads with its damage, which a record the game files give no
    // round for does not have; it then leads with the first figures it does.
    const primary = build(vocabulary.primary, true);
    const rest = build(vocabulary.rest, false);
    if (primary.length) return [...primary, ...rest];

    const promoted = vocabulary.primary.length
      ? rest.slice(0, 2).map((stat) => ({ ...stat, primary: true }))
      : [];

    return [...promoted, ...rest.slice(promoted.length)];
  });
};
