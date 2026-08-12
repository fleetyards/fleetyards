<script lang="ts">
export default {
  name: "ModelsCompareDefense",
};
</script>

<script lang="ts" setup>
import CompareSection from "@/frontend/components/Compare/Models/Section/index.vue";
import CompareStatRow from "@/frontend/components/Compare/Models/StatRow/index.vue";
import CompareChipsRow from "@/frontend/components/Compare/Models/ChipsRow/index.vue";
import { useCompareFormat } from "@/frontend/components/Compare/format";
import {
  buildCompareRows,
  hasCompareChips,
  type CompareChip,
  type CompareChipsRow as CompareChipsRowType,
  type CompareMetric,
} from "@/frontend/components/Compare/types";
import {
  computeShieldStats,
  type ShieldStats,
} from "@/frontend/composables/useShieldStats";
import {
  computeArmorStats,
  type ArmorStats,
} from "@/frontend/composables/useArmorStats";
import { useI18n } from "@/shared/composables/useI18n";
import type { Hardpoint, Model } from "@/services/fyApi";

type Props = {
  models: Model[];
  hardpointsFor: (model: Model) => Hardpoint[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const { rounded, percent } = useCompareFormat();

type DefenseStats = {
  shield: ShieldStats;
  armor: ArmorStats;
};

const statsByModel = computed<Record<string, DefenseStats>>(() =>
  Object.fromEntries(
    props.models.map((model) => {
      const hardpoints = props.hardpointsFor(model);

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

const statsFor = (model: Model) => statsByModel.value[model.slug];

const metrics: CompareMetric<DefenseStats>[] = [
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
    key: "shield-generators",
    label: t("labels.compare.shieldGenerators"),
    value: ({ shield }) =>
      shield.hasData ? String(shield.shieldCount) : undefined,
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

const rows = computed(() =>
  buildCompareRows(
    metrics,
    props.models.map((model) => ({
      key: model.slug,
      subject: statsFor(model),
    })),
  ),
);

const chipsRow = (
  key: string,
  label: string,
  chipsFor: (stats: DefenseStats) => CompareChip[],
): CompareChipsRowType => ({
  key,
  label,
  cells: props.models.map((model) => ({
    key: model.slug,
    chips: chipsFor(statsFor(model)),
  })),
});

const chipRows = computed<CompareChipsRowType[]>(() =>
  [
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
          // Anything the shield does not fully soak bleeds through to the hull
          // while it is still up — that is what ballistics exploit.
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
      "armor-self-resistance",
      t("labels.defense.armorSelfResistance"),
      ({ armor }) =>
        armor.selfResistances.map((entry) => ({
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
  ].filter(hasCompareChips),
);

const hasData = computed(() =>
  props.models.some((model) => {
    const stats = statsFor(model);

    return stats.shield.hasData || stats.armor.hasData;
  }),
);
</script>

<template>
  <CompareSection
    v-if="hasData"
    id="compare-defense"
    :title="t('labels.defense.title')"
  >
    <CompareStatRow v-for="row in rows" :key="row.key" :row="row" />
    <CompareChipsRow v-for="row in chipRows" :key="row.key" :row="row" />

    <div class="compare-hint">{{ t("labels.defense.hint") }}</div>
  </CompareSection>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Compare/compareLegend";
</style>
