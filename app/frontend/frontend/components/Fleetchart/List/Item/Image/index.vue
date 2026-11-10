<script lang="ts">
export default {
  name: "FleetchartListItemImage",
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

const loaded = ref(false);

watch(
  () => props.src,
  () => {
    loaded.value = false;
  },
);
</script>

<template>
  <img
    v-if="src"
    :src="src"
    :style="{
      width: internalWidth,
      height: !loaded && height ? `${height}px` : undefined,
      'max-height': height ? `${height}px` : undefined,
      'max-width': maxWidth,
    }"
    :alt="label"
    :class="{ 'skeleton-well': !loaded }"
    class="fleetchart-item-image"
    @load="loaded = true"
    @error="loaded = true"
  />
  <span v-else>
    <i class="fa-light fa-question-circle" />
    <p>{{ label }}</p>
  </span>
</template>

<style lang="scss" scoped>
@import "@/shared/components/skeleton";
</style>
