<script lang="ts">
export default {
  name: "CompareModelsRow",
};
</script>

<script lang="ts" setup>
import { type Model } from "@/services/fyApi";

type Props = {
  rowKey: string;
  models: Model[];
  headline?: boolean;
  slim?: boolean;
  sticky?: boolean;
  stickyLeft?: boolean;
  section?: boolean;
  centered?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  models: () => [],
  headline: false,
  slim: false,
  sticky: false,
  stickyLeft: false,
  section: false,
  centered: false,
});

const cssClasses = computed(() => {
  return {
    "compare-row-headline": props.headline,
    "compare-row-slim": props.slim,
    sticky: props.sticky,
    "compare-row-section": props.section,
  };
});
</script>

<template>
  <div class="row compare-row" :class="cssClasses">
    <div
      class="col-12 compare-row-label"
      :class="{ 'sticky-left': props.stickyLeft }"
    >
      <slot name="label" />
    </div>
    <div
      v-for="model in models"
      :key="`${model.slug}-${rowKey}`"
      class="col-12 compare-row-item"
      :class="{ centered: props.centered }"
    >
      <slot name="default" :model="model" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
