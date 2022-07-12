<template>
  <div
    :key="`${backgroundImage}-${uuid}`"
    v-lazy:background-image="backgroundImage"
    class="background-image"
  />
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import axios from 'axios'
import backgroundImage0webp from '@/images/bg-0.webp'
import backgroundImage2webp from '@/images/bg-2.webp'
import backgroundImage5webp from '@/images/bg-5.webp'
import backgroundImage6webp from '@/images/bg-6.webp'
import backgroundImage7webp from '@/images/bg-7.webp'
import backgroundImage8webp from '@/images/bg-8.webp'
import backgroundImage404webp from '@/images/bg-404.webp'
import backgroundImage0jpg from '@/images/bg-0.jpg'
import backgroundImage2jpg from '@/images/bg-2.jpg'
import backgroundImage5jpg from '@/images/bg-5.jpg'
import backgroundImage6jpg from '@/images/bg-6.jpg'
import backgroundImage7jpg from '@/images/bg-7.jpg'
import backgroundImage8jpg from '@/images/bg-8.jpg'
import backgroundImage404jpg from '@/images/bg-404.jpg'

@Component<BackgroundImage>({})
export default class BackgroundImage extends Vue {
  webpSupported: boolean = true

  backgroundImages: Fucntion[] = {
    webp: {
      'bg-0': () => require('@/images/bg-0.webp'),
      'bg-2': () => backgroundImage2webp,
      'bg-5': () => backgroundImage5webp,
      'bg-6': () => require('@/images/bg-6.webp'),
      'bg-7': () => backgroundImage7webp,
      'bg-8': () => backgroundImage8webp,
      'bg-404': () => backgroundImage404webp,
    },
    jpg: {
      'bg-0': () => backgroundImage0jpg,
      'bg-2': () => backgroundImage2jpg,
      'bg-5': () => backgroundImage5jpg,
      'bg-6': () => backgroundImage6jpg,
      'bg-7': () => backgroundImage7jpg,
      'bg-8': () => backgroundImage8jpg,
      'bg-404': () => backgroundImage404jpg,
    },
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
      () => false
    )

    return this.webpSupported
  }
}
</script>
