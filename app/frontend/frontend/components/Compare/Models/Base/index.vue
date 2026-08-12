<script lang="ts">
export default {
  name: "ModelsCompareBase",
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

const { number, uec, dollar, text } = useCompareFormat();

// Dimensions and mass carry no direction on purpose — a longer or heavier ship is
// neither better nor worse, and a winner marker there would be an opinion the data
// does not support.
const metrics: CompareMetric<Model>[] = [
  {
    key: "manufacturer",
    label: t("model.manufacturer"),
    value: (model) => text(model.manufacturer?.name),
  },
  {
    key: "production-status",
    label: t("model.productionStatus"),
    value: (model) =>
      model.productionStatus
        ? t(`labels.model.productionStatus.${model.productionStatus}`)
        : undefined,
  },
  {
    key: "focus",
    label: t("model.focus"),
    value: (model) => text(model.focus),
  },
  {
    key: "classification",
    label: t("model.classification"),
    value: (model) => text(model.classificationLabel),
  },
  {
    key: "size",
    label: t("model.size"),
    value: (model) => text(model.metrics.sizeLabel),
  },
  {
    key: "length",
    label: t("model.length"),
    value: (model) => number(model.metrics.length, "distance"),
  },
  {
    key: "beam",
    label: t("model.beam"),
    value: (model) => number(model.metrics.beam, "distance"),
  },
  {
    key: "height",
    label: t("model.height"),
    value: (model) => number(model.metrics.height, "distance"),
  },
  {
    key: "mass",
    label: t("model.mass"),
    value: (model) => number(model.metrics.mass, "weight"),
  },
  {
    key: "cargo",
    label: t("model.cargo"),
    direction: "higher",
    raw: (model) => model.metrics.cargo,
    value: (model) => number(model.metrics.cargo, "cargo"),
  },
  {
    key: "price",
    label: t("model.price"),
    direction: "lower",
    html: true,
    raw: (model) => model.price,
    value: (model) => uec(model.price),
  },
  {
    key: "pledge-price",
    label: t("model.pledgePrice"),
    direction: "lower",
    raw: (model) => model.pledgePrice,
    value: (model) => dollar(model.pledgePrice),
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
    id="compare-base"
    :title="t('labels.metrics.base')"
  >
    <CompareStatRow v-for="row in rows" :key="row.key" :row="row" />
  </CompareSection>
</template>
