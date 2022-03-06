<template>
  <transition name="fade">
    <div
      v-if="loading"
      :class="{
        fixed: fixed,
        inline: inline,
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

<script>
export default {
  name: 'LoaderComponent',

  props: {
    fixed: {
      default: false,
      type: Boolean,
    },

    inline: {
      default: false,
      type: Boolean,
    },

    loading: {
      default: false,
      type: Boolean,
    },

    progress: {
      default: null,
      type: Number,
    },
  },
}
</script>
