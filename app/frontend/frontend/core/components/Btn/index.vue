<template>
  <component
    :is="btnType"
    v-bind="btnProps"
    class="panel-btn"
    :class="cssClasses"
    :disabled="disabled || loading"
  >
    <BtnInner :loading="loading">
      <slot />
    </BtnInner>
  </component>
</template>

<script>
import BtnInner from '@/frontend/core/components/Btn/Inner/index.vue'

export default {
  name: 'BtnComponent',
  components: {
    BtnInner,
  },

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

    routeActiveClass: {
      default: null,
      type: String,
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
          ['default', 'transparent', 'link', 'danger', 'dropdown'].indexOf(
            value
          ) !== -1
        )
      },
    },
  },

  computed: {
    btnProps() {
      if (this.to) {
        return {
          activeClass: this.routeActiveClass,
          // event: this.disabled ? '' : 'click',
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
      if (this.to && !this.disabled) return 'router-link'

      if (this.href) return 'a'

      return 'button'
    },

    cssClasses() {
      return {
        'active': this.active,
        'disabled': this.disabled,
        'panel-btn-block': this.block,
        'panel-btn-danger': this.variant === 'danger',
        'panel-btn-dropdown-link': this.variant === 'dropdown',
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
