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
      <div class="cube1 cube" />
      <div class="cube2 cube" />
      <div class="cube4 cube" />
      <div class="cube3 cube" />
    </div>
  </transition>
</template>

<script>
export default {
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
  },
}
</script>
