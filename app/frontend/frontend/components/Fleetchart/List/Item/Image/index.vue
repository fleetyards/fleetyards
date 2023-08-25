<template>
  <img
    v-if="src"
    :src="src"
    :style="{
      width: `${width}px`,
      'max-height': height ? `${height}px` : undefined,
      'max-width': maxWidth,
    }"
    :alt="label"
    class="fleetchart-item-image"
  />
  <span v-else>
    <i class="fal fa-question-circle" />
    <p>{{ label }}</p>
  </span>
</template>

<script lang="ts" setup>
type Props = {
  src: string;
  label: string;
  width: number;
  height?: number;
  maxWidth?: number;
};

withDefaults(defineProps<Props>(), {
  height: undefined,
  maxWidth: undefined,
});
</script>

<script lang="ts">
export default {
  name: "FleetchartListItemImage",
};
</script>
