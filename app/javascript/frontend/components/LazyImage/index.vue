<template>
  <component
    :is="componentType"
    :href="href"
    class="lazy-image"
  >
    <img
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
      if (this.href) {
        return 'a'
      }
      return 'div'
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
