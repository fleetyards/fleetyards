<script lang="ts">
export default {
  name: "FleetchartListItemImage",
};
</script>

<script lang="ts" setup>
type Props = {
  src: string;
  label: string;
  length: number;
  scale: number;
  sourceWidth?: number;
  sourceHeight?: number;
};

const props = withDefaults(defineProps<Props>(), {
  sourceWidth: undefined,
  sourceHeight: undefined,
});

const lengthMultiplicator = computed(() => (props.scale / 100) * 4);

const imgWidth = computed(() => props.length * lengthMultiplicator.value);

const imgHeight = computed(() => {
  if (props.sourceWidth && props.sourceHeight) {
    return (imgWidth.value * props.sourceHeight) / props.sourceWidth;
  }

  return imgWidth.value;
});

// After -90deg rotation: visual width = original height, visual height = original width
const wrapperWidth = computed(() => imgHeight.value);
const wrapperHeight = computed(() => imgWidth.value);
</script>

<template>
  <div
    v-if="src"
    class="fleetchart-item-image-rotator"
    :style="{
      width: `${wrapperWidth}px`,
      height: `${wrapperHeight}px`,
    }"
  >
    <img
      :src="src"
      :style="{
        width: `${imgWidth}px`,
      }"
      :alt="label"
      class="fleetchart-item-image"
    />
  </div>
  <span v-else>
    <i class="fa-light fa-question-circle" />
    <p>{{ label }}</p>
  </span>
</template>

<style lang="scss" scoped>
.fleetchart-item-image-rotator {
  position: relative;
  display: inline-block;

  .fleetchart-item-image {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%) rotate(-90deg);
  }
}
</style>
