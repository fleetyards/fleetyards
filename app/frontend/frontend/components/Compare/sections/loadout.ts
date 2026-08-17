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
  computeHullPartGroups,
  HULL_CATEGORY_COLORS,
} from "@/frontend/composables/useHullParts";
import { useI18n } from "@/shared/composables/useI18n";
import {
  HardpointCategoryEnum,
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

// Slot classes, not hardpoint groups. Eight parallel component lists were never a
// comparison — and each list wanted ~450px, which is what dragged the whole table wide.
// A row per slot class answers "what does each ship put here" and fits a narrow column.
const SLOTS: {
  key: string;
  label: string;
  category: HardpointCategoryEnum;
  // Guns and internals hide inside mounts, so most slots have to recurse.
  deep?: boolean;
  // Categories to stop at rather than descend into. Missiles are WEAPONS-category
  // components nested under a rack, so without this the main-gun row swallows them —
  // as do the guns mounted inside a turret, which belong to the turret's own row.
  stopAt?: HardpointCategoryEnum[];
}[] = [
  {
    key: "guns",
    label: "labels.compare.slots.guns",
    category: HardpointCategoryEnum.WEAPONS,
    deep: true,
    stopAt: [
      HardpointCategoryEnum.MISSILE_RACKS,
      HardpointCategoryEnum.TURRET,
      HardpointCategoryEnum.BOMBCOMPARTMENTS,
    ],
  },
  {
    key: "turrets",
    label: "labels.compare.slots.turrets",
    category: HardpointCategoryEnum.TURRET,
    deep: true,
  },
  {
    key: "missiles",
    label: "labels.compare.slots.missiles",
    category: HardpointCategoryEnum.MISSILE_RACKS,
    deep: true,
  },
  {
    key: "shields",
    label: "labels.compare.slots.shields",
    category: HardpointCategoryEnum.SHIELDGENERATOR,
    deep: true,
  },
  {
    key: "power-plants",
    label: "labels.compare.slots.powerPlants",
    category: HardpointCategoryEnum.POWERPLANT,
    deep: true,
  },
  {
    key: "coolers",
    label: "labels.compare.slots.coolers",
    category: HardpointCategoryEnum.COOLER,
    deep: true,
  },
  {
    key: "quantum-drives",
    label: "labels.compare.slots.quantumDrives",
    category: HardpointCategoryEnum.QUANTUMDRIVE,
    deep: true,
  },
  {
    key: "thrusters",
    label: "labels.compare.slots.thrusters",
    category: HardpointCategoryEnum.MAIN_THRUSTERS,
  },
  {
    key: "countermeasures",
    label: "labels.compare.slots.countermeasures",
    category: HardpointCategoryEnum.COUNTERMEASURES,
    deep: true,
  },
];

function collect(
  hardpoints: Hardpoint[] | undefined,
  slot: (typeof SLOTS)[number],
  found: Hardpoint[] = [],
): Hardpoint[] {
  for (const hardpoint of hardpoints || []) {
    if (hardpoint.category === slot.category && hardpoint.component) {
      found.push(hardpoint);
      // A fitted component's own children are its internals, not more of this slot.
      continue;
    }

    if (hardpoint.category && slot.stopAt?.includes(hardpoint.category)) {
      continue;
    }

    if (slot.deep && hardpoint.hardpoints?.length) {
      collect(hardpoint.hardpoints, slot, found);
    }
  }

  return found;
}

export const useLoadoutSections = (
  models: MaybeRefOrGetter<Model[]>,
  hardpointsFor: (model: Model) => Hardpoint[],
) => {
  const { t } = useI18n();
  const { rounded, percent } = useCompareFormat();

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
          ),
        ]),
      ),
  );

  const defenseStats = computed(
    () =>
      new Map<string, { shield: ShieldStats; armor: ArmorStats }>(
        toValue(models).map((model) => {
          const hardpoints = hardpointsFor(model);

          return [
            model.slug,
            {
              shield: computeShieldStats(hardpoints),
              armor: computeArmorStats(hardpoints),
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
        raw: (s) => (s.hasData ? s.dps.total : undefined),
        value: (s) => (s.hasData ? rounded(s.dps.total, "integer") : undefined),
      },
      {
        key: "sustained",
        label: t("labels.combat.sustained"),
        unit: "DPS",
        direction: "higher",
        raw: (s) => (s.hasData ? s.sustainedDps.total : undefined),
        value: (s) =>
          s.hasData ? rounded(s.sustainedDps.total, "integer") : undefined,
      },
      {
        key: "alpha",
        label: t("labels.combat.alpha"),
        unit: "DMG",
        direction: "higher",
        raw: (s) => (s.hasData ? s.alpha.total : undefined),
        value: (s) =>
          s.hasData ? rounded(s.alpha.total, "integer") : undefined,
      },
      {
        key: "weapons",
        label: t("labels.combat.weapons"),
        direction: "higher",
        raw: (s) => (s.hasData ? s.weaponCount : undefined),
        value: (s) => (s.hasData ? String(s.weaponCount) : undefined),
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
    ]);
  });

  // ── Defense ─────────────────────────────────────────────────────────────────
  const defense = computed<CompareSection | undefined>(() => {
    const list = toValue(models);
    const subjects = list.map((model) => ({
      key: model.slug,
      subject: defenseStats.value.get(model.slug)!,
    }));

    type Defense = { shield: ShieldStats; armor: ArmorStats };

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

  // ── Loadout by slot ─────────────────────────────────────────────────────────
  // Cells carry the hardpoints themselves; the table renders the ship page's own
  // `HardpointItems`, which stacks them and picks the per-category item variant.
  const loadout = computed<CompareSection | undefined>(() => {
    const list = toValue(models);

    const rows = SLOTS.map<CompareTableRow>((slot) => ({
      kind: "fit",
      key: slot.key,
      label: t(slot.label),
      category: slot.category,
      cells: list.map((model) => ({
        key: model.slug,
        hardpoints: collect(hardpointsFor(model), slot),
      })),
    })).filter((row) => hasRowData([row]));

    return section("loadout", t("labels.compare.loadoutBySlot"), rows);
  });

  return { combat, defense, hull, loadout };
};
