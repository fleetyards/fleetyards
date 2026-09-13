<script lang="ts">
export default {
  name: "ProgressBar",
};
</script>

<script lang="ts" setup>
type Props = {
  progress?: number;
  // What the bar says. Defaults to the percentage, which is what every caller
  // before contracts wanted; a contract line says "240 / 800 SCU" instead,
  // because the fraction is not the number the reader is working with.
  label?: string;
};

const props = withDefaults(defineProps<Props>(), {
  progress: 0,
  label: undefined,
});

const barLabel = computed(() => props.label ?? `${props.progress} %`);

const progressWidth = computed(() => {
  return `${props.progress}%`;
});
</script>

<template>
  <div class="progress-bar">
    <span class="progress-bar__label">{{ barLabel }}</span>
    <div class="progress-bar__fill" :style="{ width: progressWidth }"></div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
