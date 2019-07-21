<template>
  <div
    :class="{
      'panel-outer-spacing': outerSpacing,
    }"
    class="panel-wrapper"
  >
    <div
      :class="{
        [variantClass]: true,
      }"
      class="panel"
    >
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
    variant: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'primary'].indexOf(value) !== -1
      },
    },
  },

  computed: {
    variantClass() {
      return `panel-${this.variant}`
    },
  },
}
</script>
