<template>
  <transition name="fade">
    <span
      v-if="loading"
      class="small-loader"
    >
      <div class="rhombus" />
      <div class="rhombus" />
      <div class="rhombus" />
    </span>
  </transition>
</template>

<script>
export default {
  props: {
    loading: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
