<template>
  <div
    :key="`${backgroundImageKey}-${uuid}`"
    class="background-image"
    :class="{
      [backgroundImageKey]: true,
      webp: webpSupported,
    }"
  />
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import axios from 'axios'

@Component<BackgroundImage>({})
export default class BackgroundImage extends Vue {
  webpSupported = true

  backgroundImageFallback = 'bg-6'

  get uuid() {
    return this._uid
  }

  get backgroundImageKey() {
    if (this.$route.meta.backgroundImage) {
      return this.$route.meta.backgroundImage
    }

    return this.backgroundImageFallback
  }

  async created() {
    this.checkWebpSupport()
  }

  async checkWebpSupport() {
    if (typeof createImageBitmap === 'undefined') {
      return false
    }

    const webpData =
      'data:image/webp;base64,UklGRh4AAABXRUJQVlA4TBEAAAAvAAAAAAfQ//73v/+BiOh/AAA='
    const response = await axios.get(webpData, { responseType: 'blob' })

    this.webpSupported = await createImageBitmap(response.data).then(
      () => true,
      () => false
    )

    return this.webpSupported
  }
}
</script>
