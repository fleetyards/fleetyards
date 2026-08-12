<script lang="ts">
export default {
  name: "ModelsCompareSpeed",
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

const anyGround = (models: Model[]) =>
  models.some((model) => model.metrics.isGroundVehicle);

const anyFlight = (models: Model[]) =>
  models.some((model) => !model.metrics.isGroundVehicle);

const speed = (
  key: string,
  label: string,
  pick: (model: Model) => number | undefined,
  visible?: (models: Model[]) => boolean,
): CompareMetric<Model> => ({
  key,
  label,
  direction: "higher",
  raw: pick,
  value: (model) => number(pick(model), "speed"),
  visible,
});

const rotation = (
  key: string,
  label: string,
  pick: (model: Model) => number | undefined,
): CompareMetric<Model> => ({
  key,
  label,
  direction: "higher",
  raw: pick,
  value: (model) => number(pick(model), "rotation"),
  visible: anyFlight,
});

const metrics: CompareMetric<Model>[] = [
  speed(
    "scm-speed",
    t("model.scmSpeed"),
    (model) => model.speeds.scmSpeed,
    anyFlight,
  ),
  speed(
    "scm-speed-boosted",
    t("model.scmSpeedBoosted"),
    (model) => model.speeds.scmSpeedBoosted,
    anyFlight,
  ),
  speed(
    "max-speed",
    t("model.maxSpeed"),
    (model) => model.speeds.maxSpeed,
    anyFlight,
  ),
  speed(
    "reverse-speed-boosted",
    t("model.reverseSpeedBoosted"),
    (model) => model.speeds.reverseSpeedBoosted,
    anyFlight,
  ),
  speed(
    "ground-max-speed",
    t("model.compare.groundMaxSpeed"),
    (model) => model.speeds.groundMaxSpeed,
    anyGround,
  ),
  speed(
    "ground-reverse-speed",
    t("model.compare.groundReverseSpeed"),
    (model) => model.speeds.groundReverseSpeed,
    anyGround,
  ),
  speed(
    "ground-acceleration",
    t("model.groundAcceleration"),
    (model) => model.speeds.groundAcceleration,
    anyGround,
  ),
  speed(
    "ground-decceleration",
    t("model.groundDecceleration"),
    (model) => model.speeds.groundDecceleration,
    anyGround,
  ),
  rotation("pitch", t("model.pitch"), (model) => model.speeds.pitch),
  rotation(
    "pitch-boosted",
    t("model.pitchBoosted"),
    (model) => model.speeds.pitchBoosted,
  ),
  rotation("yaw", t("model.yaw"), (model) => model.speeds.yaw),
  rotation(
    "yaw-boosted",
    t("model.yawBoosted"),
    (model) => model.speeds.yawBoosted,
  ),
  rotation("roll", t("model.roll"), (model) => model.speeds.roll),
  rotation(
    "roll-boosted",
    t("model.rollBoosted"),
    (model) => model.speeds.rollBoosted,
  ),
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
    id="compare-speed"
    :title="t('labels.metrics.speed')"
  >
    <CompareStatRow v-for="row in rows" :key="row.key" :row="row" />
  </CompareSection>
</template>
