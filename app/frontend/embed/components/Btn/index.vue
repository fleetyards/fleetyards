<template>
  <component
    :is="btnType"
    v-bind="btnProps"
    :class="cssClasses"
    :disabled="disabled || loading"
  >
    <BtnInner :loading="loading">
      <slot />
    </BtnInner>
  </component>
</template>

<script>
import BtnInner from '@/embed/components/Btn/Inner/index.vue'

export default {
  name: 'BtnComponent',

  components: { BtnInner },

  props: {
    loading: {
      type: Boolean,
      default: false,
    },

    to: {
      type: Object,
      default: null,
    },

    href: {
      type: String,
      default: null,
    },

    type: {
      type: String,
      default: 'button',
      validator(value) {
        return ['button', 'submit'].indexOf(value) !== -1
      },
    },

    variant: {
      type: String,
      default: 'default',
      validator(value) {
        return (
          ['default', 'transparent', 'link', 'danger'].indexOf(value) !== -1
        )
      },
    },

    size: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'small', 'large'].indexOf(value) !== -1
      },
    },

    exact: {
      type: Boolean,
      default: false,
    },

    block: {
      type: Boolean,
      default: false,
    },

    mobileBlock: {
      type: Boolean,
      default: false,
    },

    inline: {
      type: Boolean,
      default: false,
    },

    textInline: {
      type: Boolean,
      default: false,
    },

    active: {
      type: Boolean,
      default: false,
    },

    disabled: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    btnType() {
      if (this.to) return 'router-link'

      if (this.href) return 'a'

      return 'button'
    },

    btnProps() {
      if (this.to) {
        return {
          to: this.to,
          exact: this.exact,
        }
      }

      if (this.href) {
        return {
          href: this.href,
          target: '_blank',
          rel: 'noopener',
        }
      }

      return {
        type: this.type,
      }
    },

    cssClasses() {
      return {
        'panel-btn': true,
        'panel-btn-submit': this.type === 'submit',
        'panel-btn-transparent': this.variant === 'transparent',
        'panel-btn-link': this.variant === 'link',
        'panel-btn-danger': this.variant === 'danger',
        'panel-btn-small': this.size === 'small',
        'panel-btn-large': this.size === 'large',
        'panel-btn-block': this.block,
        'panel-btn-inline': this.inline,
        'panel-btn-text-inline': this.textInline,
        'panel-btn-mobile-block': this.mobileBlock,
        'active': this.active,
      }
    },
  },
}
</script>
