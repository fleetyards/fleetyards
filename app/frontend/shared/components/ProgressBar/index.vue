<script lang="ts">
export default {
  name: "ProgressBar",
};
</script>

<script lang="ts" setup>
type Props = {
  progress?: number;
};

const props = withDefaults(defineProps<Props>(), {
  progress: 0,
});

const progressWidth = computed(() => {
  return `${props.progress}%`;
});
</script>

<template>
  <div class="progress-bar">
    <span class="progress-bar__label">{{ props.progress }} %</span>
    <div class="progress-bar__fill" :style="{ width: progressWidth }"></div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
