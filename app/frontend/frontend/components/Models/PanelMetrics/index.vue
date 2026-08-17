<script lang="ts">
export default {
  name: "PanelMetrics",
};
</script>

<script lang="ts" setup>
import ModelMetricRows from "@/shared/components/ModelMetricRows/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useModelMetricRows } from "@/shared/composables/useModelMetricRows";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t, toNumber, toUEC } = useI18n();

const { groups } = useModelMetricRows(() => props.model, {
  t,
  toNumber,
  toUEC,
});
</script>

<template>
  <div class="panel-metrics">
    <ModelMetricRows :groups="groups" />
  </div>
</template>

<style scoped>
/*
 * The blocks used to carry their own 10px 15px through `metrics-padding` and were
 * separated by an `hr.slim-spacer`; the padding is this component's now and the
 * rows and divider come from ModelMetricRows.
 */
.panel-metrics {
  padding: 14px 16px 16px;
}
</style>
