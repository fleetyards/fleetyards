<script lang="ts">
export default {
  name: "FleetchartListPanzoomItemImage",
};
</script>

<script lang="ts" setup>
type Props = {
  src: string;
  label: string;
  width: number;
  height?: number;
};

withDefaults(defineProps<Props>(), {
  height: undefined,
});
</script>

<template>
  <img
    v-if="src"
    :src="src"
    :style="{
      width: `${width}px`,
      'max-height': height ? `${height}px` : undefined,
    }"
    :alt="label"
    class="fleetchart-item-image"
  />
  <span v-else>
    <i class="fa-light fa-question-circle" />
    <p>{{ label }}</p>
  </span>
</template>
