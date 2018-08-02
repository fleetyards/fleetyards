<template>
  <transition name="fade">
    <div class="text-center">
      <div
        :class="{
          'fixed': fixed,
        }"
        class="loader"
      >
        <div class="cube1 cube"/>
        <div class="cube2 cube"/>
        <div class="cube4 cube"/>
        <div class="cube3 cube"/>
      </div>
    </div>
  </transition>
</template>

<script>
export default {
  props: {
    fixed: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
