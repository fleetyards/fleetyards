<template>
  <div
    class="row"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ t("labels.metrics.base") }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <div class="col-6">
          <div class="metrics-label">{{ t("starsystem.type") }}:</div>
          <div v-tooltip="starsystem.type" class="metrics-value">
            {{ starsystem.type }}
          </div>
        </div>
        <div class="col-6">
          <div class="metrics-label">{{ t("starsystem.size") }}:</div>
          <div v-tooltip="starsystem.size" class="metrics-value">
            {{ toAu(starsystem.size) }}
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

const { t, toAu } = useI18n();
</script>

<script lang="ts">
export default {
  name: "StarsystemsBaseMetrics",
};
</script>
