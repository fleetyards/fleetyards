<template>
  <transition name="fade">
    <span v-if="loading" class="small-loader">
      <div class="rhombus" />
      <div class="rhombus" />
      <div class="rhombus" />
    </span>
  </transition>
</template>

<script>
export default {
  name: 'SmallLoader',

  props: {
    loading: {
      default: false,
      type: Boolean,
    },
  },
}
</script>
