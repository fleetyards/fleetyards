import {
  EquipmentToolActionKindEnum,
  EquipmentTypeEnum,
  type Equipment,
  type EquipmentToolAction,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import {
  damageTotal,
  multiplierChange,
  signed,
} from "@/frontend/utils/gearFigures";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";

export type EquipmentStatKey =
  | "alphaDamage"
  | "dps"
  | "blastDamage"
  | "blastRadius"
  | "meleeDamage"
  | "tractorForce"
  | "tractorRange"
  | "healRange"
  | "doseRate"
  | "repairRate"
  | "salvageRate"
  | "miningPower"
  | "extinguishRange"
  | "healthRestored"
  | "instability"
  | "resistance"
  | "clusterFactor"
  | "optimalChargeWindow"
  | "zoom"
  | "recoilChange"
  | "spreadChange"
  | "damageChange"
  | "fireRateChange"
  | "soundRadiusChange"
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
//
// A type flagged `promote` leads with the first figures it has when its
// primary ones are missing: a grenade has no DPS but has a blast, a
// multi-tool none of the tractor figures a tractor tool leads with.
const VOCABULARY: Record<
  string,
  { primary: EquipmentStatKey[]; rest: EquipmentStatKey[]; promote?: boolean }
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
    rest: [
      "blastDamage",
      "blastRadius",
      "meleeDamage",
      "rateOfFire",
      "range",
      "weaponClass",
      "magazineSize",
      "volume",
    ],
    promote: true,
  },
  [EquipmentTypeEnum.TOOL]: {
    primary: [],
    rest: [
      "tractorForce",
      "tractorRange",
      "healRange",
      "doseRate",
      "repairRate",
      "salvageRate",
      "miningPower",
      "extinguishRange",
      "dps",
      "volume",
    ],
    promote: true,
  },
  [EquipmentTypeEnum.MEDICAL]: {
    primary: ["healthRestored"],
    rest: ["volume"],
  },
  [EquipmentTypeEnum.MINING_GADGET]: {
    primary: [],
    rest: [
      "instability",
      "resistance",
      "clusterFactor",
      "optimalChargeWindow",
      "volume",
    ],
    promote: true,
  },
  [EquipmentTypeEnum.WEAPON_ATTACHMENT]: {
    primary: ["magazineSize"],
    rest: [
      "zoom",
      "damageChange",
      "fireRateChange",
      "recoilChange",
      "spreadChange",
      "soundRadiusChange",
      "volume",
    ],
    promote: true,
  },
};

// Hacking tools, flair and carried props carry nothing but their volume.
const FALLBACK = {
  primary: [] as EquipmentStatKey[],
  rest: ["volume"] as EquipmentStatKey[],
};

export const equipmentVocabulary = (equipmentType?: string | null) =>
  VOCABULARY[equipmentType ?? ""] ?? FALLBACK;

// The figures read off the detail payload's `stats` rather than a column.
const STATS_KEYS: EquipmentStatKey[] = [
  "blastDamage",
  "blastRadius",
  "meleeDamage",
  "tractorForce",
  "tractorRange",
  "healRange",
  "doseRate",
  "repairRate",
  "salvageRate",
  "miningPower",
  "extinguishRange",
  "healthRestored",
  "instability",
  "resistance",
  "clusterFactor",
  "optimalChargeWindow",
  "zoom",
  "recoilChange",
  "spreadChange",
  "damageChange",
  "fireRateChange",
  "soundRadiusChange",
];

// Whether an item's card shows anything only the detail payload carries --
// armour and clothing read their columns alone, so a list row is complete.
export const equipmentCardReadsStats = (equipmentType?: string | null) => {
  const vocabulary = equipmentVocabulary(equipmentType);

  return [...vocabulary.primary, ...vocabulary.rest].some((key) =>
    STATS_KEYS.includes(key),
  );
};

type Figure = {
  value: (item: Equipment) => number | null | undefined;
  units?: string;
  // What the figure is shown in, where that differs from what it is stored in.
  shown?: (value: number) => number;
  // A change rather than an amount, so a rise carries its plus sign.
  signed?: boolean;
};

type Label = { label: (item: Equipment) => string | null | undefined };

// The figures below the flat columns, read off the detail payload's `stats`.
// A list record carries no `stats`, so these stay empty there.
const best = (
  item: Equipment,
  kind: EquipmentToolActionKindEnum,
  field: keyof EquipmentToolAction,
) => {
  const values = (item.stats?.toolActions || [])
    .filter((action) => action.kind === kind)
    .map((action) => action[field])
    .filter((value): value is number => typeof value === "number");

  return values.length ? Math.max(...values) : undefined;
};

const miningModifier = (
  item: Equipment,
  key: "instability" | "resistance" | "clusterFactor" | "optimalChargeWindow",
) => item.stats?.mining?.modifiers?.[key];

// Where each stat is read from: a number, or a label the API already words.
const SOURCES: Record<EquipmentStatKey, Figure | Label> = {
  alphaDamage: { value: (item) => item.alphaDamage, units: "damage" },
  dps: { value: (item) => item.dps, units: "dps" },
  blastDamage: {
    value: (item) =>
      damageTotal(item.stats?.explosion?.damage) ??
      damageTotal(item.stats?.ammo?.explosion?.damage),
    units: "damage",
  },
  blastRadius: {
    value: (item) =>
      item.stats?.explosion?.maxRadius ??
      item.stats?.ammo?.explosion?.maxRadius,
    units: "distance",
  },
  meleeDamage: {
    value: (item) => {
      const hits = (item.stats?.melee?.attacks || [])
        .map((attack) => damageTotal(attack.damage))
        .filter((value): value is number => value != null);

      return hits.length ? Math.max(...hits) : undefined;
    },
    units: "damage",
  },
  tractorForce: {
    value: (item) =>
      best(item, EquipmentToolActionKindEnum.TRACTOR, "maxForce"),
    units: "newton",
  },
  tractorRange: {
    value: (item) =>
      best(item, EquipmentToolActionKindEnum.TRACTOR, "maxDistance"),
    units: "distance",
  },
  healRange: {
    value: (item) => best(item, EquipmentToolActionKindEnum.HEAL, "range"),
    units: "distance",
  },
  doseRate: {
    value: (item) => best(item, EquipmentToolActionKindEnum.HEAL, "doseRate"),
  },
  repairRate: {
    value: (item) =>
      best(item, EquipmentToolActionKindEnum.REPAIR, "healthRate"),
  },
  salvageRate: {
    value: (item) =>
      best(item, EquipmentToolActionKindEnum.SALVAGE, "healthRate"),
  },
  miningPower: {
    value: (item) => best(item, EquipmentToolActionKindEnum.MINING, "power"),
  },
  extinguishRange: {
    value: (item) =>
      best(item, EquipmentToolActionKindEnum.EXTINGUISH, "range"),
    units: "distance",
  },
  healthRestored: {
    value: (item) =>
      item.stats?.consumable?.effects?.find(
        (effect) => effect.kind === "health",
      )?.amount,
  },
  instability: {
    value: (item) => miningModifier(item, "instability"),
    units: "percent",
    signed: true,
  },
  resistance: {
    value: (item) => miningModifier(item, "resistance"),
    units: "percent",
    signed: true,
  },
  clusterFactor: {
    value: (item) => miningModifier(item, "clusterFactor"),
    units: "percent",
    signed: true,
  },
  optimalChargeWindow: {
    value: (item) => miningModifier(item, "optimalChargeWindow"),
    units: "percent",
    signed: true,
  },
  zoom: { value: (item) => item.stats?.modifier?.zoom, units: "zoom" },
  recoilChange: {
    value: (item) => {
      const recoil = item.stats?.modifier?.recoil;

      return multiplierChange(recoil?.pitch ?? recoil?.yaw);
    },
    units: "percent",
    signed: true,
  },
  spreadChange: {
    value: (item) => multiplierChange(item.stats?.modifier?.spread?.max),
    units: "percent",
    signed: true,
  },
  damageChange: {
    value: (item) => multiplierChange(item.stats?.modifier?.damage),
    units: "percent",
    signed: true,
  },
  fireRateChange: {
    value: (item) => multiplierChange(item.stats?.modifier?.fireRate),
    units: "percent",
    signed: true,
  },
  soundRadiusChange: {
    value: (item) => multiplierChange(item.stats?.modifier?.soundRadius),
    units: "percent",
    signed: true,
  },
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
    const text = figure(
      value !== undefined && source.shown ? source.shown(value) : value,
      source.units,
    );

    return text && source.signed && value !== undefined
      ? signed(text, value)
      : text;
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

        return [
          { key, label: t(`labels.equipment.stats.${key}`), value, primary },
        ];
      });

    // A weapon leads with its damage, which a record the game files give no
    // round for does not have; it then leads with the first figures it does,
    // and so does a tool or a gadget.
    // Volume never leads: it says how much room the item takes, not what it
    // does.
    const strip = ({
      key: _key,
      ...stat
    }: { key: EquipmentStatKey } & HardpointStat) => stat;
    const primary = build(vocabulary.primary, true);
    const rest = build(vocabulary.rest, false);
    if (primary.length) return [...primary, ...rest].map(strip);

    const promotable = vocabulary.promote
      ? rest.filter((stat) => stat.key !== "volume").slice(0, 2)
      : [];

    return [
      ...promotable.map((stat) => ({ ...stat, primary: true })),
      ...rest.filter((stat) => !promotable.includes(stat)),
    ].map(strip);
  });
};
