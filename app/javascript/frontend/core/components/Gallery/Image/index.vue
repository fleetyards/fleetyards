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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import LazyImage from 'frontend/core/components/LazyImage'

@Component<GalleryImage>({
  components: {
    LazyImage,
  },
})
export default class GalleryImage extends Vue {
  @Prop({ required: true }) src!: string

  @Prop({ default: 'image' }) alt!: string

  @Prop({ default: null }) title!: string

  @Prop({ default: null }) href!: string

  openInNewTab(url) {
    window.open(url, '_blank')
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
