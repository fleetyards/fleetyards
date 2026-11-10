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

const props = withDefaults(defineProps<Props>(), {
  height: undefined,
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
      width: `${width}px`,
      height: !loaded && height ? `${height}px` : undefined,
      'max-height': height ? `${height}px` : undefined,
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
