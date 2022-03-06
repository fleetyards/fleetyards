<template>
  <div
    :class="{
      'panel-outer-spacing': outerSpacing,
      'panel-highlight': highlight,
    }"
    class="panel-wrapper"
  >
    <div
      :class="{
        [variantClass]: true,
        [transparencyClass]: true,
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
  name: 'PanelComponent',

  props: {
    forText: {
      type: Boolean,
      default: false,
    },

    highlight: {
      type: Boolean,
      default: false,
    },

    outerSpacing: {
      type: Boolean,
      default: true,
    },

    transparency: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'more', 'complete'].indexOf(value) !== -1
      },
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
    transparencyClass() {
      return `panel-transparency-${this.transparency}`
    },

    variantClass() {
      return `panel-${this.variant}`
    },
  },
}
</script>
