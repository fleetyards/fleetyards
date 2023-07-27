<template>
  <div
    class="row"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ t("labels.metrics.levels") }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <div class="col-4">
          <div class="metrics-label">{{ t("starsystem.population") }}:</div>
          <div v-tooltip="starsystem.population" class="metrics-value">
            {{ starsystem.population }}
          </div>
        </div>
        <div class="col-4">
          <div class="metrics-label">{{ t("starsystem.economy") }}:</div>
          <div v-tooltip="starsystem.economy" class="metrics-value">
            {{ starsystem.economy }}
          </div>
        </div>
        <div class="col-4">
          <div class="metrics-label">{{ t("starsystem.danger") }}:</div>
          <div v-tooltip="starsystem.danger" class="metrics-value">
            {{ starsystem.danger }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/frontend/composables/useI18n";
import type { StarsystemMinimal } from "@/services/fyApi";

type Props = {
  starsystem: StarsystemMinimal;
  padding?: boolean;
};

withDefaults(defineProps<Props>(), {
  padding: false,
});

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "StarsystemsLevelsMetrics",
};
</script>
