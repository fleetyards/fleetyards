<template>
  <button
    type="button"
    :class="cssClasses"
    :disabled="disabled || loading"
    @click="toggle"
  >
    <BtnInner :loading="loading">
      <slot name="left" />
    </BtnInner>
    <BtnInner :loading="loading">
      <slot name="right" />
    </BtnInner>
  </button>
</template>

<script>
import BtnInner from 'frontend/components/Btn/Inner'

export default {
  name: 'Btn',

  components: {
    BtnInner,
  },

  props: {
    loading: {
      type: Boolean,
      default: false,
    },

    activeLeft: {
      type: Boolean,
      default: true,
    },

    activeRight: {
      type: Boolean,
      default: false,
    },

    variant: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'danger'].indexOf(value) !== -1
      },
    },

    size: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'small', 'large'].indexOf(value) !== -1
      },
    },

    inline: {
      type: Boolean,
      default: false,
    },

    disabled: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    cssClasses() {
      return {
        'panel-btn': true,
        'panel-btn-toggle': true,
        'panel-btn-danger': this.variant === 'danger',
        'panel-btn-small': this.size === 'small',
        'panel-btn-large': this.size === 'large',
        'panel-btn-inline': this.inline,
        'active-left': this.activeLeft,
        'active-right': this.activeRight,
      }
    },
  },

  methods: {
    toggle() {
      if (this.activeRight) {
        this.$emit('toggle:left')
      } else {
        this.$emit('toggle:right')
      }
    },
  },
}
</script>
