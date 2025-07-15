<script lang="ts">
export default {
  name: "ModelsCompareSpeed",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import ModelsRow from "@/frontend/components/Compare/Models/Row/index.vue";
import RowTitle from "@/frontend/components/Compare/Models/Row/Title/index.vue";
import RowLabel from "@/frontend/components/Compare/Models/Row/Label/index.vue";
import RowValue from "@/frontend/components/Compare/Models/Row/Value/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
  slim?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  slim: false,
});

const { t, toNumber } = useI18n();

const visible = ref(false);

onMounted(() => {
  visible.value = props.models.length > 0;
});

watch(
  () => props.models,
  () => {
    visible.value = props.models.length > 0;
  },
);

const toggle = () => {
  visible.value = !visible.value;
};

const rows = [
  {
    key: "speed-scm-speed",
    label: t("model.scmSpeed"),
    value: (model: Model) => toNumber(model.speeds.scmSpeed, "speed"),
  },
  {
    key: "speed-scm-speed-boosted",
    label: t("model.scmSpeedBoosted"),
    value: (model: Model) => toNumber(model.speeds.scmSpeedBoosted, "speed"),
  },
  {
    key: "speed-max-speed",
    label: t("model.maxSpeed"),
    value: (model: Model) => toNumber(model.speeds.maxSpeed, "speed"),
  },
  {
    key: "speed-reverse-speed-boosted",
    label: t("model.reverseSpeedBoosted"),
    value: (model: Model) =>
      toNumber(model.speeds.reverseSpeedBoosted, "speed"),
  },
  {
    key: "speed-ground-max-speed",
    label: t("model.compare.groundMaxSpeed"),
    value: (model: Model) => toNumber(model.speeds.groundMaxSpeed, "speed"),
  },
  {
    key: "speed-ground-reverse-speed",
    label: t("model.compare.groundReverseSpeed"),
    value: (model: Model) => toNumber(model.speeds.groundReverseSpeed, "speed"),
  },
  {
    key: "speed-pitch",
    label: t("model.pitch"),
    value: (model: Model) => toNumber(model.speeds.pitch, "rotation"),
  },
  {
    key: "speed-pitch-boosted",
    label: t("model.pitchBoosted"),
    value: (model: Model) => toNumber(model.speeds.pitchBoosted, "rotation"),
  },
  {
    key: "speed-yaw",
    label: t("model.yaw"),
    value: (model: Model) => toNumber(model.speeds.yaw, "rotation"),
  },
  {
    key: "speed-yaw-boosted",
    label: t("model.yawBoosted"),
    value: (model: Model) => toNumber(model.speeds.yawBoosted, "rotation"),
  },
  {
    key: "speed-roll",
    label: t("model.roll"),
    value: (model: Model) => toNumber(model.speeds.roll, "rotation"),
  },
  {
    key: "speed-roll-boosted",
    label: t("model.rollBoosted"),
    value: (model: Model) => toNumber(model.speeds.rollBoosted, "rotation"),
  },
];
</script>

<template>
  <ModelsRow :models="models" row-key="speed" :slim="slim" sticky-left section>
    <template #label>
      <RowTitle
        :active="visible"
        :title="t('labels.metrics.speed')"
        @click="toggle"
      />
    </template>
  </ModelsRow>

  <Collapsed id="speed" :visible="visible" class="row">
    <div class="col-12">
      <ModelsRow
        v-for="row in rows"
        :key="row.key"
        :models="models"
        :row-key="row.key"
        :slim="slim"
        sticky-left
      >
        <template #label>
          <RowLabel>
            {{ row.label }}
          </RowLabel>
        </template>
        <template #default="{ model }">
          <RowValue>
            <!-- eslint-disable-next-line vue/no-v-html -->
            <span v-html="row.value(model)" />
          </RowValue>
        </template>
      </ModelsRow>
    </div>
  </Collapsed>
</template>
