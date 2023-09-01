<template>
  <div class="row metrics-padding">
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ t("labels.metrics.crew") }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <div class="col-6 col-md-6">
          <div class="metrics-label">{{ t("model.minCrew") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.crew.min, "people") }}
          </div>
        </div>
        <div class="col-6 col-md-6">
          <div class="metrics-label">{{ t("model.maxCrew") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.crew.max, "people") }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/frontend/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

defineProps<Props>();

const { t, toNumber } = useI18n();
</script>

<script lang="ts">
export default {
  name: "ModelCrewMetrics",
};
</script>
