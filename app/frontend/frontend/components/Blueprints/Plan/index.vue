<script lang="ts">
export default {
  name: "BlueprintPlan",
};
</script>

<script lang="ts" setup>
import { type MediaFile } from "@/services/fyApi";

type Props = {
  image: MediaFile;
  variant?: "row" | "panel";
};

const props = withDefaults(defineProps<Props>(), {
  variant: "row",
});

// The panel spans the rail, which a 500px render only just covers on a dense
// screen.
const src = computed(() =>
  props.variant === "panel"
    ? props.image.mediumUrl || props.image.smallUrl
    : props.image.smallUrl,
);
</script>

<template>
  <span
    class="blueprint-plan"
    :class="`blueprint-plan--${variant}`"
    data-test="blueprint-plan"
  >
    <img
      class="blueprint-plan__image"
      :src="src"
      alt=""
      :loading="variant === 'row' ? 'lazy' : undefined"
      data-test="blueprint-plan-image"
    />
  </span>
</template>

<style lang="scss" scoped>
@import "index";
</style>
