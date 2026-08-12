<script lang="ts">
export default {
  name: "ModelsCompareHull",
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
  computeHullPartGroups,
  HULL_CATEGORY_COLORS,
} from "@/frontend/composables/useHullParts";
import { useI18n } from "@/shared/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const { rounded } = useCompareFormat();

const hullParts = (model: Model) => model.metrics.hullParts || [];

const hullDoors = (model: Model) => model.metrics.hullDoors || [];

// Doors are their own damage area, deliberately outside hull HP — shooting one
// does not damage the hull.
const doorHealth = (model: Model) =>
  hullDoors(model).reduce((sum, door) => sum + door.health, 0);

const compositionFor = (model: Model) =>
  computeHullPartGroups(hullParts(model))
    .filter((group) => group.total > 0)
    .map((group) => ({
      key: group.category,
      label: group.label,
      value: group.total,
      color: HULL_CATEGORY_COLORS[group.category],
    }));

const metrics: CompareMetric<Model>[] = [
  {
    key: "hull-hp",
    label: t("labels.hull.hullHp"),
    unit: "HP",
    direction: "higher",
    raw: (model) => model.metrics.hullHealth || undefined,
    value: (model) =>
      model.metrics.hullHealth
        ? rounded(model.metrics.hullHealth, "integer")
        : undefined,
  },
  {
    key: "hull-parts",
    label: t("labels.hull.parts"),
    value: (model) =>
      hullParts(model).length ? String(hullParts(model).length) : undefined,
    visible: (models) => models.some((model) => hullParts(model).length > 0),
  },
  {
    key: "hull-doors",
    label: t("labels.hull.doors"),
    unit: "HP",
    direction: "higher",
    raw: (model) => doorHealth(model) || undefined,
    value: (model) =>
      doorHealth(model) ? rounded(doorHealth(model), "integer") : undefined,
    visible: (models) => models.some((model) => hullDoors(model).length > 0),
  },
];

const rows = computed(() =>
  buildCompareRows(
    metrics,
    props.models.map((model) => ({ key: model.slug, subject: model })),
  ),
);

// Only the categories actually present across the compared ships, so the shared
// legend never lists a colour no bar uses.
const legend = computed(() => {
  const seen = new Map<string, string>();

  props.models.forEach((model) => {
    compositionFor(model).forEach((segment) => {
      if (!seen.has(segment.key)) {
        seen.set(segment.key, segment.label);
      }
    });
  });

  return [...seen].map(([key, label]) => ({
    key,
    label,
    color: HULL_CATEGORY_COLORS[key],
  }));
});

const hasData = computed(() =>
  props.models.some(
    (model) =>
      !!model.metrics.hullHealth ||
      hullParts(model).length > 0 ||
      hullDoors(model).length > 0,
  ),
);
</script>

<template>
  <CompareSection
    v-if="hasData"
    id="compare-hull"
    :title="t('labels.hull.title')"
  >
    <CompareStatRow v-for="row in rows" :key="row.key" :row="row" />

    <CompareContentRow v-if="legend.length" :models="models" align="stretch">
      <template #label>
        <div class="compare-legend">
          <div class="compare-legend__title">
            {{ t("labels.hull.composition") }}
          </div>
          <div
            v-for="entry in legend"
            :key="entry.key"
            class="compare-legend__entry"
          >
            <span
              class="compare-legend__swatch"
              :style="{ background: entry.color }"
            />
            {{ t(entry.label) }}
          </div>
        </div>
      </template>
      <template #default="{ model }">
        <CompositionBar :segments="compositionFor(model)" bar-only />
      </template>
    </CompareContentRow>

    <div class="compare-hint">{{ t("labels.hull.hint") }}</div>
  </CompareSection>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Compare/compareLegend";
</style>
