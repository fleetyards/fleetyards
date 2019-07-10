<template>
  <component
    :is="componentType"
    v-bind="componentArgs"
    class="lazy-image"
  >
    <img
      :key="src"
      v-lazy="image"
      :alt="alt"
    >
  </component>
</template>

<script>
import errorImage from 'images/store_image.jpg'
import loadingImage from 'images/loading.svg'

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
    image() {
      return {
        src: this.src,
        error: errorImage,
        loading: loadingImage,
      }
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
