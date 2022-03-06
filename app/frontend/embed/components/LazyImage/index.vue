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
    alt: {
      default: 'image',
      type: String,
    },

    href: {
      default: null,
      type: String,
    },

    src: {
      required: true,
      type: String,
    },

    to: {
      default: null,
      type: Object,
    },
  },

  computed: {
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

    componentType() {
      if (this.to) {
        return 'router-link'
      }
      if (this.href) {
        return 'a'
      }
      return 'div'
    },
  },
}
</script>
