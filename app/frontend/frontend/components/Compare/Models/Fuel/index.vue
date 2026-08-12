<script lang="ts">
export default {
  name: "ModelsCompareFuel",
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
import {
  HardpointCategoryEnum,
  type ComponentQuantumDrive,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";

type Props = {
  models: Model[];
  hardpointsFor: (model: Model) => Hardpoint[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const { number, rounded } = useCompareFormat();

const findQuantumDrive = (
  hardpoints: Hardpoint[] | undefined,
): ComponentQuantumDrive | undefined => {
  for (const hardpoint of hardpoints || []) {
    if (
      hardpoint.category === HardpointCategoryEnum.QUANTUMDRIVE &&
      hardpoint.component?.typeData
    ) {
      return hardpoint.component.typeData as ComponentQuantumDrive;
    }

    const nested = findQuantumDrive(hardpoint.hardpoints);

    if (nested) {
      return nested;
    }
  }

  return undefined;
};

// Max jump range on a full tank: quantum fuel (SCU) × 1000 / the drive's per-Gm
// consumption (mSCU/Gm). Matches erkul.games and spviewer.eu.
const quantumRange = (model: Model) => {
  const tank = model.metrics.quantumFuelTankSize;
  const consumption = findQuantumDrive(
    props.hardpointsFor(model),
  )?.quantumFuelConsumption;

  if (!tank || !consumption) {
    return undefined;
  }

  return (tank * 1000) / consumption;
};

const crossSection = (model: Model, axis: "x" | "y" | "z") =>
  model.metrics.signatureCrossSection?.[axis];

const axisMetric = (axis: "x" | "y" | "z"): CompareMetric<Model> => ({
  key: `cross-section-${axis}`,
  label: t(`labels.compare.crossSection.${axis}`),
  // A smaller radar cross-section is harder to detect and harder to hit.
  direction: "lower",
  raw: (model) => crossSection(model, axis),
  value: (model) => number(crossSection(model, axis)),
  visible: (models) => models.some((model) => !!crossSection(model, axis)),
});

const metrics: CompareMetric<Model>[] = [
  {
    key: "hydrogen-fuel",
    label: t("model.hydrogenFuelTankSize"),
    direction: "higher",
    raw: (model) => model.metrics.hydrogenFuelTankSize,
    value: (model) => number(model.metrics.hydrogenFuelTankSize, "cargo"),
  },
  {
    key: "quantum-fuel",
    label: t("model.quantumFuelTankSize"),
    direction: "higher",
    raw: (model) => model.metrics.quantumFuelTankSize,
    value: (model) => number(model.metrics.quantumFuelTankSize, "cargo"),
  },
  {
    key: "quantum-range",
    label: t("labels.hardpoint.quantumDrives.range"),
    unit: "Gm",
    direction: "higher",
    raw: quantumRange,
    value: (model) => rounded(quantumRange(model), "integer"),
  },
  {
    key: "weapon-pool",
    label: t("labels.compare.weaponPoolSize"),
    direction: "higher",
    raw: (model) => model.metrics.weaponPoolSize,
    value: (model) => rounded(model.metrics.weaponPoolSize, "integer"),
  },
  axisMetric("x"),
  axisMetric("y"),
  axisMetric("z"),
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
    id="compare-fuel"
    :title="t('labels.compare.fuelAndQuantum')"
  >
    <CompareStatRow v-for="row in rows" :key="row.key" :row="row" />
  </CompareSection>
</template>
