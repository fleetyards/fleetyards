<script lang="ts">
export default {
  name: "FetchProgressBar",
};
</script>

<script lang="ts" setup>
import { useIsFetching } from "@tanstack/vue-query";
import debounce from "lodash.debounce";

const isFetching = useIsFetching();

const progress = ref(0);
const started = ref(false);
const visible = ref(false);

let trickleTimer: ReturnType<typeof setTimeout> | null = null;

const trickle = () => {
  if (!started.value) return;

  let increment: number;
  if (progress.value < 0.2) {
    increment = 0.1;
  } else if (progress.value < 0.5) {
    increment = 0.04;
  } else if (progress.value < 0.8) {
    increment = 0.02;
  } else if (progress.value < 0.99) {
    increment = 0.005;
  } else {
    increment = 0;
  }

  progress.value = Math.min(progress.value + increment, 1);
  trickleTimer = setTimeout(trickle, 200);
};

const start = () => {
  if (started.value) return;
  started.value = true;
  visible.value = true;
  progress.value = 0;
  trickle();
};

const done = () => {
  if (!started.value) return;
  started.value = false;

  if (trickleTimer) {
    clearTimeout(trickleTimer);
    trickleTimer = null;
  }

  progress.value = 1;

  setTimeout(() => {
    visible.value = false;
    setTimeout(() => {
      progress.value = 0;
    }, 300);
  }, 200);
};

const updateStatus = () => {
  if (unref(isFetching)) {
    start();
  } else {
    done();
  }
};

const debouncedUpdateStatus = debounce(updateStatus, 300);

watch(
  () => unref(isFetching),
  () => {
    if (started.value) {
      debouncedUpdateStatus();
    } else {
      updateStatus();
    }
  },
);

onUnmounted(() => {
  if (trickleTimer) {
    clearTimeout(trickleTimer);
  }
});
</script>

<template>
  <div
    class="fetch-progress-bar"
    :class="{ 'fetch-progress-bar--visible': visible }"
    :style="{ transform: `scaleX(${progress})` }"
  />
</template>

<style lang="scss" scoped>
@import "index";
</style>
