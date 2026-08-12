<script lang="ts">
export default {
  name: "ModelsCompareCombat",
};
</script>

<script lang="ts" setup>
import CompareSection from "@/frontend/components/Compare/Models/Section/index.vue";
import CompareStatRow from "@/frontend/components/Compare/Models/StatRow/index.vue";
import CompareContentRow from "@/frontend/components/Compare/Models/ContentRow/index.vue";
import CompositionBar from "@/frontend/components/Models/CompositionBar/index.vue";
import { useCompareFormat } from "@/frontend/components/Compare/format";
import {
  buildCompareRows,
  type CompareMetric,
} from "@/frontend/components/Compare/types";
import {
  computeLoadoutStats,
  type DamageBreakdown,
  type LoadoutStats,
} from "@/frontend/composables/useLoadoutStats";
import { useI18n } from "@/shared/composables/useI18n";
import type { Hardpoint, Model } from "@/services/fyApi";

type Props = {
  models: Model[];
  hardpointsFor: (model: Model) => Hardpoint[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const { rounded } = useCompareFormat();

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

const statsByModel = computed<Record<string, LoadoutStats>>(() =>
  Object.fromEntries(
    props.models.map((model) => [
      model.slug,
      computeLoadoutStats(
        props.hardpointsFor(model),
        model.metrics.weaponPoolSize,
      ),
    ]),
  ),
);

const statsFor = (model: Model) => statsByModel.value[model.slug];

const metrics: CompareMetric<LoadoutStats>[] = [
  {
    key: "dps",
    label: t("labels.combat.dps"),
    unit: "DPS",
    direction: "higher",
    raw: (stats) => (stats.hasData ? stats.dps.total : undefined),
    value: (stats) =>
      stats.hasData ? rounded(stats.dps.total, "integer") : undefined,
  },
  {
    key: "sustained",
    label: t("labels.combat.sustained"),
    unit: "DPS",
    direction: "higher",
    raw: (stats) => (stats.hasData ? stats.sustainedDps.total : undefined),
    value: (stats) =>
      stats.hasData ? rounded(stats.sustainedDps.total, "integer") : undefined,
  },
  {
    key: "alpha",
    label: t("labels.combat.alpha"),
    unit: "DMG",
    direction: "higher",
    raw: (stats) => (stats.hasData ? stats.alpha.total : undefined),
    value: (stats) =>
      stats.hasData ? rounded(stats.alpha.total, "integer") : undefined,
  },
  {
    key: "weapons",
    label: t("labels.combat.weapons"),
    direction: "higher",
    raw: (stats) => (stats.hasData ? stats.weaponCount : undefined),
    value: (stats) => (stats.hasData ? String(stats.weaponCount) : undefined),
  },
  {
    key: "missile-damage",
    label: t("labels.combat.missileDamage"),
    direction: "higher",
    raw: (stats) => stats.missileDamage || undefined,
    value: (stats) =>
      stats.missileDamage ? rounded(stats.missileDamage, "integer") : undefined,
    visible: (all) => all.some((stats) => stats.missileDamage > 0),
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

const compositionFor = (model: Model) => {
  const stats = statsFor(model);

  return DAMAGE_TYPES.map(({ key, label, color }) => ({
    key,
    label,
    color,
    value: stats.dps[key],
  }))
    .filter((entry) => entry.value > 0)
    .sort((a, b) => b.value - a.value);
};

const hasData = computed(() =>
  props.models.some((model) => statsFor(model).hasData),
);
</script>

<template>
  <CompareSection
    v-if="hasData"
    id="compare-combat"
    :title="t('labels.combat.title')"
  >
    <CompareStatRow v-for="row in rows" :key="row.key" :row="row" />

    <CompareContentRow :models="models" align="stretch">
      <template #label>
        <div class="compare-legend">
          <div class="compare-legend__title">
            {{ t("labels.combat.composition") }}
          </div>
          <div
            v-for="type in DAMAGE_TYPES"
            :key="type.key"
            class="compare-legend__entry"
          >
            <span
              class="compare-legend__swatch"
              :style="{ background: type.color }"
            />
            {{ t(type.label) }}
          </div>
        </div>
      </template>
      <template #default="{ model }">
        <CompositionBar :segments="compositionFor(model)" bar-only />
      </template>
    </CompareContentRow>

    <div class="compare-hint">{{ t("labels.combat.hint") }}</div>
  </CompareSection>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Compare/compareLegend";
</style>
