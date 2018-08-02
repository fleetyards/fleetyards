<template>
  <div
    :class="{
      'panel-outer-spacing': outerSpacing,
    }"
    class="panel-wrapper"
  >
    <div class="panel-outer-border panel-outer-border-top">
      <div class="panel-outer-border-left" />
      <div class="panel-outer-border-right" />
    </div>
    <div class="panel">
      <div class="panel-inner-border panel-inner-border-top">
        <div class="panel-inner-border-bg" />
      </div>
      <div class="panel-inner">
        <slot />
      </div>
      <div class="panel-inner-border panel-inner-border-bottom">
        <div class="panel-inner-border-bg" />
      </div>
    </div>
    <div class="panel-outer-border panel-outer-border-bottom">
      <div class="panel-outer-border-left" />
      <div class="panel-outer-border-right" />
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

<style lang="scss">
  @import "./styles/index";
</style>
