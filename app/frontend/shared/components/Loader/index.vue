<script lang="ts">
export default {
  name: "LoaderComponent",
};
</script>

<script lang="ts" setup>
type Props = {
  loading?: boolean;
  fixed?: boolean;
  relative?: boolean;
  inline?: boolean;
  progress?: number;
  // Shown at once. By default a loader waits half a second, so a quick load
  // never flashes one; where the content around it already reacts to the click,
  // that wait reads as nothing happening.
  immediate?: boolean;
};

withDefaults(defineProps<Props>(), {
  loading: false,
  fixed: false,
  inline: false,
  progress: undefined,
  immediate: false,
});
</script>

<template>
  <transition :name="immediate ? 'fade-quick' : 'fade'">
    <div
      v-if="loading"
      :class="{
        'loader--fixed': fixed,
        'loader--relative': relative,
        'loader--inline': inline,
      }"
      data-test="loader"
      class="loader"
    >
      <div class="cube1 cube"></div>
      <div class="cube2 cube"></div>
      <div class="cube4 cube"></div>
      <div class="cube3 cube"></div>

      <transition name="fade">
        <div
          v-if="progress != null && progress < 100"
          class="progress progress-left"
          :style="{ width: `${progress}%` }"
        ></div>
      </transition>

      <transition name="fade">
        <div
          v-if="progress != null && progress < 100"
          class="progress progress-right"
          :style="{ height: `${progress}%` }"
        ></div>
      </transition>
    </div>
  </transition>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
