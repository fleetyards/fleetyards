<script lang="ts">
export default {
  name: "CompareShipImage",
};
</script>

<script lang="ts" setup>
type Props = {
  src: string;
  label: string;
  width?: number;
  height?: number;
  maxWidth?: string;
  maxHeight?: string;
};

const props = withDefaults(defineProps<Props>(), {
  height: undefined,
  width: undefined,
  maxWidth: undefined,
});

const internalWidth = computed(() => {
  return `${props.width}px` || "auto";
});
</script>

<template>
  <img
    v-if="src"
    :src="src"
    :style="{
      width: internalWidth,
      'max-height': height ? `${height}px` : undefined,
      'max-width': maxWidth,
    }"
    :alt="label"
  />
  <span v-else>
    <i class="fa-light fa-question-circle" />
    <p>{{ label }}</p>
  </span>
</template>
