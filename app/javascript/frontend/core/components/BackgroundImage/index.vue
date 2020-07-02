<template>
  <div
    :key="backgroundImage"
    v-lazy:background-image="backgroundImage"
    class="background-image"
  />
</template>

<script>
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import axios from 'axios'

@Component<BackgroundImage>({})
export default class BackgroundImage extends Vue {
  webpSupported: boolean = true

  backgroundImages: Fucntion[] = {
    /* eslint-disable global-require */
    webp: {
      'bg-0': () => {
        return require('images/bg-0.webp').default
      },
      'bg-2': () => {
        return require('images/bg-2.webp').default
      },
      'bg-5': () => {
        return require('images/bg-5.webp').default
      },
      'bg-6': () => {
        return require('images/bg-6.webp').default
      },
      'bg-7': () => {
        return require('images/bg-7.webp').default
      },
      'bg-8': () => {
        return require('images/bg-8.webp').default
      },
      'bg-404': () => {
        return require('images/bg-404.webp').default
      },
    },
    jpg: {
      'bg-0': () => {
        return require('images/bg-0.jpg').default
      },
      'bg-2': () => {
        return require('images/bg-2.jpg').default
      },
      'bg-5': () => {
        return require('images/bg-5.jpg').default
      },
      'bg-6': () => {
        return require('images/bg-6.jpg').default
      },
      'bg-7': () => {
        return require('images/bg-7.jpg').default
      },
      'bg-8': () => {
        return require('images/bg-8.jpg').default
      },
      'bg-404': () => {
        return require('images/bg-404.jpg').default
      },
    },
    /* eslint-enable global-require */
  }

  get backgroundImageKey() {
    if (this.$route.meta.backgroundImage) {
      return this.$route.meta.backgroundImage
    }

    return 'bg-6'
  }

  get backgroundImage() {
    return this.backgroundImages[this.webpSupported ? 'webp' : 'jpg'][
      this.backgroundImageKey
    ]()
  }

  created() {
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
      () => false,
    )

    return this.webpSupported
  }
}
</script>
