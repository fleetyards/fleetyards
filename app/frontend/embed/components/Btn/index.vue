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
    active: {
      type: Boolean,
      default: false,
    },

    block: {
      type: Boolean,
      default: false,
    },

    disabled: {
      default: false,
      type: Boolean,
    },

    exact: {
      type: Boolean,
      default: false,
    },

    href: {
      type: String,
      default: null,
    },

    inline: {
      type: Boolean,
      default: false,
    },

    loading: {
      default: false,
      type: Boolean,
    },

    mobileBlock: {
      type: Boolean,
      default: false,
    },

    size: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'small', 'large'].indexOf(value) !== -1
      },
    },

    textInline: {
      type: Boolean,
      default: false,
    },

    to: {
      type: Object,
      default: null,
    },

    type: {
      default: 'button',
      type: String,
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
  },

  computed: {
    btnProps() {
      if (this.to) {
        return {
          exact: this.exact,
          to: this.to,
        }
      }

      if (this.href) {
        return {
          href: this.href,
          rel: 'noopener',
          target: '_blank',
        }
      }

      return {
        type: this.type,
      }
    },

    btnType() {
      if (this.to) return 'router-link'

      if (this.href) return 'a'

      return 'button'
    },

    cssClasses() {
      return {
        'active': this.active,
        'panel-btn': true,
        'panel-btn-block': this.block,
        'panel-btn-danger': this.variant === 'danger',
        'panel-btn-inline': this.inline,
        'panel-btn-large': this.size === 'large',
        'panel-btn-link': this.variant === 'link',
        'panel-btn-mobile-block': this.mobileBlock,
        'panel-btn-small': this.size === 'small',
        'panel-btn-submit': this.type === 'submit',
        'panel-btn-text-inline': this.textInline,
        'panel-btn-transparent': this.variant === 'transparent',
      }
    },
  },
}
</script>
