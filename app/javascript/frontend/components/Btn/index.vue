<template>
  <router-link
    v-if="to"
    :class="cssClasses"
    :to="to"
    :exact="to.exact"
    :disabled="disabled || loading"
  >
    <BtnInner :loading="loading">
      <slot />
    </BtnInner>
  </router-link>
  <a
    v-else-if="href"
    :class="cssClasses"
    :href="href"
    target="_blank"
    rel="noopener"
  >
    <BtnInner :loading="loading">
      <slot />
    </BtnInner>
  </a>
  <button
    v-else
    :type="type"
    :class="cssClasses"
    :disabled="disabled || loading"
  >
    <BtnInner :loading="loading">
      <slot />
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
        return ['default', 'transparent', 'link', 'danger'].indexOf(value) !== -1
      },
    },
    size: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'small', 'large'].indexOf(value) !== -1
      },
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
        'panel-btn-mobile-block': this.mobileBlock,
        active: this.active,
      }
    },
  },
}
</script>
