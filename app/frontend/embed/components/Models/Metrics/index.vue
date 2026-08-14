<script lang="ts">
export default {
  name: "EmbedModelMetrics",
};
</script>

<script lang="ts" setup>
import ModelMetricRows from "@/shared/components/ModelMetricRows/index.vue";
import { useI18n } from "@/embed/composables/useI18n";
import { useModelMetricRows } from "@/shared/composables/useModelMetricRows";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

// The embed's own translations, not the frontend's: same keys, 16K of `en`
// against 1.4M of eight locales. The rows themselves come from the shared
// composable so the two surfaces cannot disagree about which figures a model has.
const { t, toNumber, toUEC } = useI18n();

const { groups } = useModelMetricRows(() => props.model, {
  t,
  toNumber,
  toUEC,
});

// The summary block keeps its `top-metrics` hook: four embed specs assert it is
// visible with the details open and gone when they close.
const groupsWithHooks = computed(() =>
  groups.value.map((group, index) =>
    index === 0 ? { ...group, testId: "top-metrics" } : group,
  ),
);
</script>

<template>
  <div class="embed-model-metrics">
    <ModelMetricRows :groups="groupsWithHooks" />
  </div>
</template>

<style scoped>
.embed-model-metrics {
  padding: 14px 16px 16px;
}
</style>
