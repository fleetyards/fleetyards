<script lang="ts">
export default {
  name: "ModelsCompareCrew",
};
</script>

<script lang="ts" setup>
import CompareSection from "@/frontend/components/Compare/Models/Section/index.vue";
import CompareStatRow from "@/frontend/components/Compare/Models/StatRow/index.vue";
import { useCompareFormat } from "@/frontend/components/Compare/format";
import {
  buildCompareRows,
  hasCompareData,
  type CompareMetric,
} from "@/frontend/components/Compare/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const { number } = useCompareFormat();

// Fewer hands needed to fly is the advantage on min crew; more stations supported
// is the advantage on max.
const metrics: CompareMetric<Model>[] = [
  {
    key: "min-crew",
    label: t("model.minCrew"),
    direction: "lower",
    raw: (model) => model.crew.min,
    value: (model) => number(model.crew.min, "people"),
  },
  {
    key: "max-crew",
    label: t("model.maxCrew"),
    direction: "higher",
    raw: (model) => model.crew.max,
    value: (model) => number(model.crew.max, "people"),
  },
];

const rows = computed(() =>
  buildCompareRows(
    metrics,
    props.models.map((model) => ({ key: model.slug, subject: model })),
  ),
);
</script>

<template>
  <CompareSection
    v-if="hasCompareData(rows)"
    id="compare-crew"
    :title="t('labels.metrics.crew')"
  >
    <CompareStatRow v-for="row in rows" :key="row.key" :row="row" />
  </CompareSection>
</template>
