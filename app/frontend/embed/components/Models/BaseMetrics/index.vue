<template>
  <div
    class="row base-metrics"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div
      v-if="title"
      :class="{
        'col-lg-3': title,
      }"
      class="col-12"
    >
      <div class="metrics-title">
        {{ t("model.metrics.base") }}
      </div>
    </div>
    <div
      :class="{
        'col-lg-9': title,
      }"
      class="col-12 metrics-block"
    >
      <div class="row">
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ t("model.length") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.metrics.length, "distance") }}
          </div>
          <div class="metrics-label">{{ t("model.beam") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.metrics.beam, "distance") }}
          </div>
        </div>
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ t("model.height") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.metrics.height, "distance") }}
          </div>
          <div class="metrics-label">{{ t("model.mass") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.metrics.mass, "weight") }}
          </div>
        </div>
        <div class="col-12 col-lg-4">
          <div class="row">
            <div class="col-6 col-lg-12">
              <div class="metrics-label">{{ t("model.cargo") }}:</div>
              <div class="metrics-value">
                {{ toNumber(model.metrics.cargo, "cargo") }}
              </div>
            </div>
            <div v-if="model.price" class="col-6 col-lg-12">
              <div class="metrics-label">{{ t("model.price") }}:</div>
              <span class="metrics-value" v-html="toUEC(model.price)" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/embed/composables/useI18n";
import type { ModelMinimal } from "@/services/fyApi";

const { t, toNumber, toUEC } = useI18n();

type Props = {
  model: ModelMinimal;
  title?: boolean;
  padding?: boolean;
};

withDefaults(defineProps<Props>(), {
  title: false,
  detailed: false,
  padding: false,
});
</script>

<script lang="ts">
export default {
  name: "ModelBaseMetrics",
};
</script>
