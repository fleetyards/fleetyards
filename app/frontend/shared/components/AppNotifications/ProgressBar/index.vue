<script lang="ts">
export default {
  name: "AppNotificationsProgressBar",
};
</script>

<script lang="ts" setup>
type Props = {
  timeout?: number | false;
};

const props = defineProps<Props>();

const progress = ref(100);

const progressStyles = computed(() => {
  if (!props.timeout) {
    return;
  }

  return {
    width: `${progress.value}%`,
    transition: `width ${props.timeout}ms linear`,
  };
});

onMounted(() => {
  if (props.timeout) {
    setTimeout(() => {
      progress.value = 0;
    }, 1);
  }
});
</script>

<template>
  <div
    v-if="timeout"
    class="app-notifications__progress-bar"
    :style="progressStyles"
  />
</template>

<style lang="scss" scoped>
@import "index";
</style>
