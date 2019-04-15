<template>
  <router-link
    v-if="to"
    :class="cssClasses"
    :to="to"
    :exact="exact"
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
  >
    <BtnInner :loading="loading">
      <slot />
    </BtnInner>
  </button>
</template>

<script>
import BtnInner from 'frontend/components/Btn/Inner'

export default {
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
    },
    clear: {
      type: Boolean,
      default: false,
    },
    clean: {
      type: Boolean,
      default: false,
    },
    large: {
      type: Boolean,
      default: false,
    },
    danger: {
      type: Boolean,
      default: false,
    },
    small: {
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
    active: {
      type: Boolean,
      default: false,
    },
    exact: {
      type: Boolean,
      default: false,
    },
    primary: {
      type: Boolean,
      default: false,
    },
    inline: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    cssClasses() {
      return {
        'panel-btn': true,
        'panel-btn-clear': this.clear,
        'panel-btn-clean': this.clean,
        'panel-btn-small': this.small,
        'panel-btn-large': this.large,
        'panel-btn-block': this.block,
        'panel-btn-inline': this.inline,
        'panel-btn-primary': this.primary,
        'panel-btn-mobile-block': this.mobileBlock,
        active: this.active,
      }
    },
  },
}
</script>
