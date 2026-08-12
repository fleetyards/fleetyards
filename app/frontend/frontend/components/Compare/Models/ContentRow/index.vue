<script lang="ts">
export default {
  name: "CompareModelsContentRow",
};
</script>

<script lang="ts" setup>
import type { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
  label?: string;
  align?: "center" | "stretch" | "start";
};

withDefaults(defineProps<Props>(), {
  label: "",
  align: "center",
});
</script>

<template>
  <div class="compare-grid">
    <div class="compare-cell compare-cell--label">
      <slot name="label">{{ label }}</slot>
    </div>
    <div
      v-for="(model, index) in models"
      :key="model.slug"
      class="compare-cell compare-cell--content"
      :class="`compare-cell--content-${align}`"
    >
      <slot :model="model" :index="index" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Compare/compareGrid";

.compare-cell--content {
  flex-direction: column;
  gap: 8px;
}

.compare-cell--content-stretch {
  align-items: stretch;
}

.compare-cell--content-start {
  align-items: stretch;
  justify-content: flex-start;
}
</style>
