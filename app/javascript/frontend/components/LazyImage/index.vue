<template>
  <component
    :is="componentType"
    v-if="src"
    :key="src"
    v-lazy:background-image="src"
    v-bind="componentArgs"
    class="lazy-image"
  >
    <slot />
  </component>
</template>

<script>
export default {
  name: 'LazyImage',

  props: {
    src: {
      type: String,
      required: true,
    },
    alt: {
      type: String,
      default: 'image',
    },
    href: {
      type: String,
      default: null,
    },
    to: {
      type: Object,
      default: null,
    },
  },

  computed: {
    componentType() {
      if (this.to) {
        return 'router-link'
      }
      if (this.href) {
        return 'a'
      }
      return 'div'
    },

    componentArgs() {
      if (this.to) {
        return {
          to: this.to,
        }
      }

      if (this.href) {
        return {
          href: this.href,
        }
      }

      return {}
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
