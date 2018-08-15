<template>
  <div
    :class="{
      'panel-outer-spacing': outerSpacing,
    }"
    class="panel-wrapper"
  >
    <div class="panel">
      <div class="panel-inner">
        <slot />
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    outerSpacing: {
      type: Boolean,
      default: true,
    },
  },
}
</script>
