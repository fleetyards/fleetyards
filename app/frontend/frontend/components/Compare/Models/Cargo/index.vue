<script lang="ts">
export default {
  name: "ModelsCompareCargo",
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
import {
  containersOfSize,
  maxContainerSize,
} from "@/frontend/components/CargoGridViewer/capacity";
import { CONTAINER_DEFS } from "@/frontend/components/CargoGridViewer/constants";
import { useI18n } from "@/shared/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const { number } = useCompareFormat();

const holdsFor = (model: Model) => model.cargoHolds || [];

// Prefer the holds we can actually see over the ship-matrix total, the same way
// the ship page's cargo card does.
const totalCargo = (model: Model) => {
  const holds = holdsFor(model);

  if (!holds.length) {
    return model.metrics.cargo;
  }

  const sum = holds.reduce((total, hold) => total + (hold.capacity || 0), 0);

  return sum || model.metrics.cargo;
};

const metrics: CompareMetric<Model>[] = [
  {
    key: "cargo-total",
    label: t("model.cargo"),
    direction: "higher",
    raw: totalCargo,
    value: (model) => number(totalCargo(model), "cargo"),
  },
  {
    key: "cargo-max-container",
    label: t("labels.cargoGridViewer.maxContainerSize"),
    direction: "higher",
    raw: (model) => maxContainerSize(holdsFor(model)),
    value: (model) => {
      const size = maxContainerSize(holdsFor(model));

      return size ? `${size} SCU` : undefined;
    },
  },
  ...CONTAINER_DEFS.map<CompareMetric<Model>>((def) => ({
    key: `cargo-container-${def.size}`,
    label: t("labels.compare.containersOfSize", { size: def.size }),
    direction: "higher",
    unit: "×",
    raw: (model) => {
      const holds = holdsFor(model);

      return holds.length ? containersOfSize(holds, def.size) : undefined;
    },
    value: (model) => {
      const count = containersOfSize(holdsFor(model), def.size);

      return count > 0 ? String(count) : undefined;
    },
    // A container size nothing on screen can take is noise, not information.
    visible: (models) =>
      models.some((model) => containersOfSize(holdsFor(model), def.size) > 0),
  })),
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
    id="compare-cargo"
    :title="t('labels.metrics.cargo')"
  >
    <CompareStatRow v-for="row in rows" :key="row.key" :row="row" />
  </CompareSection>
</template>
