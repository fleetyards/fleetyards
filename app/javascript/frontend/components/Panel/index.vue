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
      <div
        :class="{
          'panel-inner-text': forText,
        }"
        class="panel-inner"
      >
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

    forText: {
      type: Boolean,
      default: false,
    },

    variant: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'primary', 'success'].indexOf(value) !== -1
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
