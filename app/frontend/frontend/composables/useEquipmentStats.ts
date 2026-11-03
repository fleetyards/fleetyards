import { EquipmentTypeEnum, type Equipment } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";

export type EquipmentStatKey =
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
    primary: ["rateOfFire", "range"],
    rest: ["weaponClass", "magazineSize", "volume"],
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

  const read = (item: Equipment, key: EquipmentStatKey): string | undefined => {
    switch (key) {
      case "damageReduction":
        return figure(item.damageReduction, "percent");
      case "temperatureRating":
        return item.temperatureRating || undefined;
      case "radiationProtection":
        return figure(item.radiationProtection, "rem");
      case "radiationScrubRate":
        return figure(item.radiationScrubRate, "remPerSecond");
      case "gForceTolerance":
        return figure(item.gForceTolerance);
      // One column, two meanings: the rounds a magazine holds, or what a suit
      // or jacket can carry. The parser keeps the figure and drops the unit,
      // which is not the same across apparel, so none is guessed here.
      case "carryingCapacity":
      case "magazineSize":
        return figure(item.storage);
      case "rateOfFire":
        return figure(item.rateOfFire, "rateOfFire");
      case "range":
        return figure(item.range, "distance");
      case "weaponClass":
        return item.weaponClassLabel || undefined;
      case "coreCompatibility":
        return item.coreCompatibilityLabel || undefined;
      case "backpackCompatibility":
        return item.backpackCompatibilityLabel || undefined;
      // In µSCU, the unit an inventory grid counts in. As SCU a jacket is
      // 0.0087, which the stat formatter would round to nothing.
      case "volume":
        return figure(
          item.volume == null ? undefined : Math.round(item.volume * 1_000_000),
          "microScu",
        );
    }
  };

  const raw = (item: Equipment, key: EquipmentStatKey): number | undefined => {
    switch (key) {
      case "damageReduction":
        return item.damageReduction ?? undefined;
      case "radiationProtection":
        return item.radiationProtection ?? undefined;
      case "radiationScrubRate":
        return item.radiationScrubRate ?? undefined;
      case "gForceTolerance":
        return item.gForceTolerance ?? undefined;
      case "carryingCapacity":
      case "magazineSize":
        return item.storage ?? undefined;
      case "rateOfFire":
        return item.rateOfFire ?? undefined;
      case "range":
        return item.range ?? undefined;
      case "volume":
        return item.volume ?? undefined;
      default:
        return undefined;
    }
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

    return [
      ...build(vocabulary.primary, true),
      ...build(vocabulary.rest, false),
    ];
  });
};
