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
          class="progress progress-left"
          :style="{ width: `${progress}%` }"
          v-if="progress != null && progress < 100"
        ></div>
      </transition>

      <transition name="fade">
        <div
          class="progress progress-right"
          :style="{ height: `${progress}%` }"
          v-if="progress != null && progress < 100"
        ></div>
      </transition>
    </div>
  </transition>
</template>

<script>
export default {
  name: 'LoaderComponent',

  props: {
    loading: {
      type: Boolean,
      default: false,
    },

    fixed: {
      type: Boolean,
      default: false,
    },

    inline: {
      type: Boolean,
      default: false,
    },

    progress: {
      type: Number,
      default: null,
    },
  },
}
</script>
