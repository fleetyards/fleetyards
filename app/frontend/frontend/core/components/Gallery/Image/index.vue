<template>
  <LazyImage
    :key="src"
    :src="src"
    :alt="alt"
    :title="title || alt"
    :href="href"
    class="image gallery-image"
    @click.native.ctrl.prevent="openInNewTab(href)"
    @click.native.meta.prevent="openInNewTab(href)"
  />
</template>

<script>
import LazyImage from '@/frontend/core/components/LazyImage/index.vue'

export default {
  name: 'GalleryImage',

  components: {
    LazyImage,
  },

  props: {
    alt: {
      type: String,
      default: 'image',
    },

    href: {
      type: String,
      default: null,
    },

    src: {
      type: String,
      required: true,
    },

    title: {
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
@import 'index.scss';
</style>
