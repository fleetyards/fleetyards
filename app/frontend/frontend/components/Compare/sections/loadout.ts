import { computed, toValue, type MaybeRefOrGetter } from "vue";
import { useCompareFormat } from "@/frontend/components/Compare/format";
import {
  hasRowData,
  valueRows,
  type CompareChip,
  type CompareMetric,
  type CompareSection,
  type CompareTableRow,
} from "@/frontend/components/Compare/types";
import {
  computeLoadoutStats,
  type DamageBreakdown,
  type LoadoutStats,
} from "@/frontend/composables/useLoadoutStats";
import {
  computeShieldStats,
  type ShieldStats,
} from "@/frontend/composables/useShieldStats";
import {
  computeArmorStats,
  type ArmorStats,
} from "@/frontend/composables/useArmorStats";
import {
  computeControllerStats,
  type ControllerStats,
} from "@/frontend/composables/useControllerStats";
import {
  computeHullPartGroups,
  HULL_CATEGORY_COLORS,
} from "@/frontend/composables/useHullParts";
import { useLoadoutLines } from "@/frontend/components/Compare/sections/lines";
import { salvageSummary } from "@/frontend/components/Compare/sections/salvageSummary";
import { useI18n } from "@/shared/composables/useI18n";
import {
  ComponentShieldFaceTypeEnum,
  HardpointCategoryEnum,
  StorageContainerKindEnum,
  type ComponentSalvageModifier,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";

const DAMAGE_TYPES: {
  key: keyof DamageBreakdown;
  label: string;
  color: string;
}[] = [
  { key: "physical", label: "labels.combat.damagePhysical", color: "#c8c8c8" },
  { key: "energy", label: "labels.combat.damageEnergy", color: "#428bca" },
  {
    key: "distortion",
    label: "labels.combat.damageDistortion",
    color: "#38bec9",
  },
  { key: "thermal", label: "labels.combat.damageThermal", color: "#fa6800" },
];

export const useLoadoutSections = (
  models: MaybeRefOrGetter<Model[]>,
  hardpointsFor: (model: Model) => Hardpoint[],
) => {
  const { t } = useI18n();
  const { number, rounded, percent } = useCompareFormat();
  const { lineRows } = useLoadoutLines(models, hardpointsFor);

  const category = (key: HardpointCategoryEnum) =>
    t(`labels.hardpoint.categories.${key}`);

  // Only a quadrant shield has faces to shift strength between.
  const quadrantCooldown = (controllers: ControllerStats) =>
    controllers.shieldFaceType === ComponentShieldFaceTypeEnum.QUADRANT
      ? controllers.reconfigurationCooldown
      : undefined;

  const section = (
    id: string,
    title: string,
    rows: CompareTableRow[],
  ): CompareSection | undefined =>
    hasRowData(rows) ? { id, title, rows } : undefined;

  const combatStats = computed(
    () =>
      new Map<string, LoadoutStats>(
        toValue(models).map((model) => [
          model.slug,
          computeLoadoutStats(
            hardpointsFor(model),
            model.metrics.weaponPoolSize,
            undefined,
            model.metrics.weaponRegenModifier,
          ),
        ]),
      ),
  );

  const defenseStats = computed(
    () =>
      new Map<
        string,
        { shield: ShieldStats; armor: ArmorStats; controllers: ControllerStats }
      >(
        toValue(models).map((model) => {
          const hardpoints = hardpointsFor(model);

          return [
            model.slug,
            {
              shield: computeShieldStats(hardpoints),
              armor: computeArmorStats(hardpoints),
              controllers: computeControllerStats(hardpoints),
            },
          ];
        }),
      ),
  );

  // ── Combat ──────────────────────────────────────────────────────────────────
  const combat = computed<CompareSection | undefined>(() => {
    const list = toValue(models);
    const subjects = list.map((model) => ({
      key: model.slug,
      subject: combatStats.value.get(model.slug)!,
    }));

    const metrics: CompareMetric<LoadoutStats>[] = [
      {
        key: "dps",
        label: t("labels.combat.dps"),
        unit: "DPS",
        direction: "higher",
        raw: (s) => (s.weaponCount > 0 ? s.dps.total : undefined),
        value: (s) =>
          s.weaponCount > 0 ? rounded(s.dps.total, "integer") : undefined,
      },
      {
        key: "sustained",
        label: t("labels.combat.sustained"),
        unit: "DPS",
        direction: "higher",
        raw: (s) => (s.weaponCount > 0 ? s.sustainedDps.total : undefined),
        value: (s) =>
          s.weaponCount > 0
            ? rounded(s.sustainedDps.total, "integer")
            : undefined,
      },
      {
        key: "alpha",
        label: t("labels.combat.alpha"),
        unit: "DMG",
        direction: "higher",
        raw: (s) => (s.weaponCount > 0 ? s.alpha.total : undefined),
        value: (s) =>
          s.weaponCount > 0 ? rounded(s.alpha.total, "integer") : undefined,
      },
      {
        key: "weapons",
        label: t("labels.combat.weapons"),
        direction: "higher",
        counts: {},
        raw: (s) => (s.weaponCount > 0 ? s.weaponCount : undefined),
        value: (s) => (s.weaponCount > 0 ? String(s.weaponCount) : undefined),
      },
      {
        key: "missile-damage",
        label: t("labels.combat.missileDamage"),
        direction: "higher",
        raw: (s) => s.missileDamage || undefined,
        value: (s) =>
          s.missileDamage ? rounded(s.missileDamage, "integer") : undefined,
        visible: (all) => all.some((s) => s.missileDamage > 0),
      },
      {
        key: "armed-missiles",
        label: t("labels.combat.armedMissiles"),
        direction: "higher",
        counts: {},
        raw: (s) => s.maxArmedMissiles,
        value: (s) =>
          s.maxArmedMissiles ? String(s.maxArmedMissiles) : undefined,
        visible: (all) => all.some((s) => (s.maxArmedMissiles || 0) > 0),
      },
      {
        key: "launch-cooldown",
        label: t("labels.hardpoint.controllers.launchCooldown"),
        unit: "s",
        direction: "lower",
        raw: (s) => s.launchCooldown,
        value: (s) => number(s.launchCooldown),
        visible: (all) => all.some((s) => typeof s.launchCooldown === "number"),
      },
    ];

    const compositionRow: CompareTableRow = {
      kind: "composition",
      key: "damage-composition",
      label: t("labels.combat.composition"),
      legend: DAMAGE_TYPES.map(({ key, label, color }) => ({
        key,
        label: t(label),
        color,
      })),
      cells: list.map((model) => {
        const stats = combatStats.value.get(model.slug)!;

        return {
          key: model.slug,
          segments: DAMAGE_TYPES.map(({ key, label, color }) => ({
            key,
            label: t(label),
            color,
            value: stats.dps[key],
          }))
            .filter((entry) => entry.value > 0)
            .sort((a, b) => b.value - a.value),
        };
      }),
    };

    return section("combat", t("labels.combat.title"), [
      ...valueRows(metrics, subjects),
      compositionRow,
      ...lineRows([
        {
          key: "guns",
          label: t("labels.compare.slots.guns"),
          categories: [HardpointCategoryEnum.WEAPONS],
        },
        ...[
          HardpointCategoryEnum.MISSILES,
          HardpointCategoryEnum.BOMBS,
          HardpointCategoryEnum.EMP,
          HardpointCategoryEnum.QUANTUMENFORCEMENTDEVICE,
        ].map((key) => ({ key, label: category(key), categories: [key] })),
      ]),
    ]);
  });

  // ── Defense ─────────────────────────────────────────────────────────────────
  const defense = computed<CompareSection | undefined>(() => {
    const list = toValue(models);
    const subjects = list.map((model) => ({
      key: model.slug,
      subject: defenseStats.value.get(model.slug)!,
    }));

    type Defense = {
      shield: ShieldStats;
      armor: ArmorStats;
      controllers: ControllerStats;
    };

    const metrics: CompareMetric<Defense>[] = [
      {
        key: "shield-hp",
        label: t("labels.defense.shieldHp"),
        unit: "HP",
        direction: "higher",
        raw: ({ shield }) => (shield.hasData ? shield.totalHp : undefined),
        value: ({ shield }) =>
          shield.hasData ? rounded(shield.totalHp, "integer") : undefined,
      },
      {
        key: "shield-regen",
        label: t("labels.defense.shieldRegen"),
        unit: "HP/s",
        direction: "higher",
        raw: ({ shield }) => (shield.hasData ? shield.totalRegen : undefined),
        value: ({ shield }) =>
          shield.hasData ? rounded(shield.totalRegen, "integer") : undefined,
      },
      {
        key: "shield-faces",
        label: t("labels.defense.shieldFaces"),
        value: ({ shield, controllers }) =>
          shield.hasData && controllers.shieldFaceType
            ? t(
                `labels.hardpoint.controllers.faces.${controllers.shieldFaceType}`,
              )
            : undefined,
        visible: (all) =>
          all.some(
            ({ shield, controllers }) =>
              shield.hasData && !!controllers.shieldFaceType,
          ),
      },
      {
        key: "shield-reconfiguration",
        label: t("labels.hardpoint.controllers.reconfigurationCooldown"),
        unit: "s",
        direction: "lower",
        raw: ({ controllers }) => quadrantCooldown(controllers),
        value: ({ controllers }) => number(quadrantCooldown(controllers)),
        visible: (all) =>
          all.some(
            ({ controllers }) => quadrantCooldown(controllers) !== undefined,
          ),
      },
      {
        key: "armor-hp",
        label: t("labels.compare.armorHp"),
        unit: "HP",
        direction: "higher",
        raw: ({ armor }) => armor.health || undefined,
        value: ({ armor }) =>
          armor.health ? rounded(armor.health, "integer") : undefined,
        visible: (all) => all.some(({ armor }) => armor.health > 0),
      },
    ];

    const chipsRow = (
      key: string,
      label: string,
      chipsFor: (stats: Defense) => CompareChip[],
    ): CompareTableRow => ({
      kind: "chips",
      key,
      label,
      cells: list.map((model) => ({
        key: model.slug,
        chips: chipsFor(defenseStats.value.get(model.slug)!),
      })),
    });

    const chipRows = [
      chipsRow(
        "shield-resistances",
        t("labels.defense.shieldResistances"),
        ({ shield }) =>
          shield.resistances.map((entry) => ({
            key: entry.key,
            label: t(entry.label),
            value: percent(entry.value) || "—",
          })),
      ),
      chipsRow(
        "shield-absorption",
        t("labels.defense.shieldAbsorption"),
        ({ shield }) =>
          shield.absorptions.map((entry) => ({
            key: entry.key,
            label: t(entry.label),
            value:
              entry.min === entry.max
                ? percent(entry.max) || "—"
                : `${percent(entry.min)} – ${percent(entry.max)}`,
            // Anything the shield does not fully soak bleeds through to the hull while
            // it is still up — that is what ballistics exploit.
            negative: entry.max < 1,
          })),
      ),
      chipsRow("deflection", t("labels.defense.deflection"), ({ armor }) =>
        armor.deflections.map((entry) => ({
          key: entry.key,
          label: t(entry.label),
          value: rounded(entry.value, "integer") || "—",
        })),
      ),
      chipsRow(
        "armor-reduction",
        t("labels.defense.armorReduction"),
        ({ armor }) =>
          armor.reductions.map((entry) => ({
            key: entry.key,
            label: t(entry.label),
            value: percent(entry.value) || "—",
            negative: entry.value < 0,
          })),
      ),
      chipsRow(
        "armor-signature",
        t("labels.defense.armorSignature"),
        ({ armor }) =>
          armor.signatures.map((entry) => ({
            key: entry.key,
            label: t(entry.label),
            value: `${entry.value > 0 ? "+" : ""}${percent(entry.value)}`,
            negative: entry.value > 0,
          })),
      ),
    ];

    return section("defense", t("labels.defense.title"), [
      ...valueRows(metrics, subjects),
      ...chipRows,
      ...lineRows(
        [
          HardpointCategoryEnum.SHIELDGENERATOR,
          HardpointCategoryEnum.COUNTERMEASURES,
        ].map((key) => ({ key, label: category(key), categories: [key] })),
      ),
    ]);
  });

  // ── Hull ────────────────────────────────────────────────────────────────────
  const hull = computed<CompareSection | undefined>(() => {
    const list = toValue(models);
    const subjects = list.map((model) => ({ key: model.slug, subject: model }));

    const parts = (model: Model) => model.metrics.hullParts || [];
    const doors = (model: Model) => model.metrics.hullDoors || [];

    // Doors are their own damage area, deliberately outside hull HP — shooting one does
    // not damage the hull.
    const doorHealth = (model: Model) =>
      doors(model).reduce((sum, door) => sum + door.health, 0);

    const compositionFor = (model: Model) =>
      computeHullPartGroups(parts(model))
        .filter((group) => group.total > 0)
        .map((group) => ({
          key: group.category,
          label: t(group.label),
          value: group.total,
          color: HULL_CATEGORY_COLORS[group.category],
        }));

    const metrics: CompareMetric<Model>[] = [
      {
        key: "hull-hp",
        label: t("labels.hull.hullHp"),
        unit: "HP",
        direction: "higher",
        raw: (m) => m.metrics.hullHealth || undefined,
        value: (m) =>
          m.metrics.hullHealth
            ? rounded(m.metrics.hullHealth, "integer")
            : undefined,
      },
      {
        key: "hull-parts",
        label: t("labels.hull.parts"),
        value: (m) => (parts(m).length ? String(parts(m).length) : undefined),
        visible: (all) => all.some((m) => parts(m).length > 0),
      },
      {
        key: "hull-doors",
        label: t("labels.hull.doors"),
        unit: "HP",
        direction: "higher",
        raw: (m) => doorHealth(m) || undefined,
        value: (m) =>
          doorHealth(m) ? rounded(doorHealth(m), "integer") : undefined,
        visible: (all) => all.some((m) => doors(m).length > 0),
      },
    ];

    // Only the categories actually present, so the shared legend never lists a colour
    // no bar uses.
    const seen = new Map<string, string>();
    list.forEach((model) =>
      compositionFor(model).forEach((segment) => {
        if (!seen.has(segment.key)) {
          seen.set(segment.key, segment.label);
        }
      }),
    );

    const compositionRow: CompareTableRow = {
      kind: "composition",
      key: "hull-composition",
      label: t("labels.hull.composition"),
      legend: [...seen].map(([key, label]) => ({
        key,
        label,
        color: HULL_CATEGORY_COLORS[key],
      })),
      cells: list.map((model) => ({
        key: model.slug,
        segments: compositionFor(model),
      })),
    };

    return section("hull", t("labels.hull.title"), [
      ...valueRows(metrics, subjects),
      compositionRow,
    ]);
  });

  // Every part of a kind across the whole loadout, nested ones included: a
  // Moth's heads sit in its turrets, a Fortune's on a tool arm.
  const partsIn = (
    hardpoints: Hardpoint[] | undefined,
    kind: HardpointCategoryEnum,
  ): Hardpoint[] =>
    (hardpoints || []).flatMap((hardpoint) => [
      ...(hardpoint.component && hardpoint.category === kind
        ? [hardpoint]
        : []),
      ...partsIn(
        hardpoint.hardpoints?.length
          ? hardpoint.hardpoints
          : hardpoint.component?.hardpoints,
        kind,
      ),
    ]);

  const storageOf = (model: Model, kind: StorageContainerKindEnum) =>
    (model.storageContainers || [])
      .filter((container) => container.kind === kind)
      .reduce((sum, container) => sum + (container.capacity || 0), 0);

  // ── Salvage ─────────────────────────────────────────────────────────────────
  const salvage = computed<CompareSection | undefined>(() => {
    const list = toValue(models);

    type Salvage = {
      heads: number;
      fastestScraper?: number;
      storage: number;
      fillerStations: number;
      crate?: number;
      reach?: number;
    };

    const subjects = list.map((model) => {
      const hardpoints = hardpointsFor(model);
      const summary = salvageSummary(hardpoints);
      const speeds = partsIn(hardpoints, HardpointCategoryEnum.SALVAGE_MODULES)
        .map(
          (part) =>
            (part.component?.typeData as ComponentSalvageModifier | undefined)
              ?.salvageSpeed,
        )
        .filter((speed): speed is number => typeof speed === "number");

      return {
        key: model.slug,
        subject: {
          heads: partsIn(hardpoints, HardpointCategoryEnum.SALVAGE_HEADS)
            .length,
          fastestScraper: speeds.length ? Math.max(...speeds) : undefined,
          storage: storageOf(model, StorageContainerKindEnum.SALVAGE),
          fillerStations: partsIn(
            hardpoints,
            HardpointCategoryEnum.SALVAGEFILLERSTATION,
          ).length,
          crate: summary?.crate?.size,
          reach: summary?.structural?.disintegration?.maxRadius,
        } satisfies Salvage,
      };
    });

    const metrics: CompareMetric<Salvage>[] = [
      {
        key: "salvage-heads",
        label: t("labels.salvageMetrics.heads"),
        direction: "higher",
        counts: {},
        raw: (s) => s.heads || undefined,
        value: (s) => (s.heads ? String(s.heads) : undefined),
      },
      {
        key: "salvage-fastest-scraper",
        label: t("labels.compare.fastestScraper"),
        unit: "×",
        direction: "higher",
        raw: (s) => s.fastestScraper,
        value: (s) => number(s.fastestScraper),
      },
      {
        key: "salvage-storage",
        label: t("labels.model.salvageStorage"),
        unit: "SCU",
        direction: "higher",
        counts: { unit: "SCU" },
        raw: (s) => s.storage || undefined,
        value: (s) => (s.storage ? number(s.storage) : undefined),
      },
      {
        key: "salvage-filler-stations",
        label: category(HardpointCategoryEnum.SALVAGEFILLERSTATION),
        counts: {},
        raw: (s) => s.fillerStations || undefined,
        value: (s) => (s.fillerStations ? String(s.fillerStations) : undefined),
      },
      {
        key: "salvage-largest-crate",
        label: t("labels.salvageMetrics.largestCrate"),
        unit: "SCU",
        direction: "higher",
        raw: (s) => s.crate,
        value: (s) => number(s.crate),
      },
      {
        key: "salvage-disintegration",
        label: t("labels.salvageMetrics.disintegration"),
        unit: "m",
        direction: "higher",
        raw: (s) => s.reach,
        value: (s) => number(s.reach),
      },
    ];

    return section("salvage", t("labels.hardpoint.groups.salvage"), [
      ...valueRows(metrics, subjects),
      ...lineRows([
        {
          key: "salvage-heads-fitted",
          label: category(HardpointCategoryEnum.SALVAGE_HEADS),
          categories: [HardpointCategoryEnum.SALVAGE_HEADS],
        },
      ]),
    ]);
  });

  // ── Mining ──────────────────────────────────────────────────────────────────
  const mining = computed<CompareSection | undefined>(() => {
    const list = toValue(models);

    type Mining = { lasers: number; ore: number };

    const subjects = list.map((model) => ({
      key: model.slug,
      subject: {
        lasers: partsIn(
          hardpointsFor(model),
          HardpointCategoryEnum.MINING_LASERS,
        ).length,
        ore: storageOf(model, StorageContainerKindEnum.ORE),
      } satisfies Mining,
    }));

    const metrics: CompareMetric<Mining>[] = [
      {
        key: "mining-lasers",
        label: category(HardpointCategoryEnum.MINING_LASERS),
        direction: "higher",
        counts: {},
        raw: (s) => s.lasers || undefined,
        value: (s) => (s.lasers ? String(s.lasers) : undefined),
      },
      {
        key: "mining-ore",
        label: t("labels.model.orePods"),
        unit: "SCU",
        direction: "higher",
        counts: { unit: "SCU" },
        raw: (s) => s.ore || undefined,
        value: (s) => (s.ore ? number(s.ore) : undefined),
      },
    ];

    return section("mining", t("labels.hardpoint.groups.mining"), [
      ...valueRows(metrics, subjects),
      ...lineRows([
        {
          key: "mining-lasers-fitted",
          label: category(HardpointCategoryEnum.MINING_LASERS),
          categories: [HardpointCategoryEnum.MINING_LASERS],
        },
      ]),
    ]);
  });

  // ── Systems and utility ─────────────────────────────────────────────────────
  const partsOnly = (
    id: string,
    title: string,
    kinds: HardpointCategoryEnum[],
  ) =>
    section(
      id,
      title,
      lineRows(
        kinds.map((key) => ({ key, label: category(key), categories: [key] })),
      ),
    );

  const systems = computed(() =>
    partsOnly("systems", t("labels.hardpoint.groups.system"), [
      HardpointCategoryEnum.POWERPLANT,
      HardpointCategoryEnum.COOLER,
      HardpointCategoryEnum.RADAR,
      HardpointCategoryEnum.LIFESUPPORT,
    ]),
  );

  const utility = computed(() =>
    partsOnly("utility", t("labels.hardpoint.groups.auxiliary"), [
      HardpointCategoryEnum.TRACTOR_BEAMS,
      HardpointCategoryEnum.MODULE,
    ]),
  );

  return { combat, defense, hull, salvage, mining, systems, utility };
};
