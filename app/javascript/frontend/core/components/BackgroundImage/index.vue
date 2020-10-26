<template>
  <div
    :key="`${backgroundImage}-${uuid}`"
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
        return require('images/bg-0.webp')
      },
      'bg-2': () => {
        return require('images/bg-2.webp')
      },
      'bg-5': () => {
        return require('images/bg-5.webp')
      },
      'bg-6': () => {
        return require('images/bg-6.webp')
      },
      'bg-7': () => {
        return require('images/bg-7.webp')
      },
      'bg-8': () => {
        return require('images/bg-8.webp')
      },
      'bg-404': () => {
        return require('images/bg-404.webp')
      },
    },
    jpg: {
      'bg-0': () => {
        return require('images/bg-0.jpg')
      },
      'bg-2': () => {
        return require('images/bg-2.jpg')
      },
      'bg-5': () => {
        return require('images/bg-5.jpg')
      },
      'bg-6': () => {
        return require('images/bg-6.jpg')
      },
      'bg-7': () => {
        return require('images/bg-7.jpg')
      },
      'bg-8': () => {
        return require('images/bg-8.jpg')
      },
      'bg-404': () => {
        return require('images/bg-404.jpg')
      },
    },
    /* eslint-enable global-require */
  }

    get uuid() {
    return this._uid
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
