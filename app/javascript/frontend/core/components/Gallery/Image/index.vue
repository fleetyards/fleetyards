<template>
  <LazyImage
    :key="src"
    :src="src"
    :alt="alt"
    :title="alt"
    :href="href"
    class="image gallery-image"
    @click.native.ctrl.prevent="openInNewTab(href)"
    @click.native.meta.prevent="openInNewTab(href)"
  />
</template>

<script>
import LazyImage from 'frontend/core/components/LazyImage'

export default {
  name: 'GalleryImage',

  components: {
    LazyImage,
  },

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

  methods: {
    openInNewTab(url) {
      window.open(url, '_blank')
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
