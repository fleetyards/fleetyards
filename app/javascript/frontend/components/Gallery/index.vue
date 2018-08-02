<template>
  <div
    id="blueimp-gallery"
    class="blueimp-gallery blueimp-gallery-controls"
  >
    <div class="slides" />
    <a class="prev">‹</a>
    <a class="next">›</a>
    <a class="close">×</a>
    <a class="play-pause" />
    <div class="indicator-wrapper">
      <ol class="indicator" />
    </div>
  </div>
</template>


<script>
import BlueimpGallery from 'blueimp-gallery/js/blueimp-gallery.min'
import VueScrollTo from 'vue-scrollto'

export default {
  props: {
    images: {
      type: Array,
      default() { return [] },
    },
    videos: {
      type: Array,
      default() { return [] },
    },
  },
  computed: {
    galleryImages() {
      return this.images.map(image => ({
        href: image.url,
        type: image.type,
        thumbnail: image.smallUrl,
      }))
    },
    galleryVideos() {
      return this.videos.map(video => ({
        href: `https://www.youtube.com/watch?v=${video.videoId}`,
        type: 'text/html',
        youtube: video.videoId,
        poster: `https://img.youtube.com/vi/${video.videoId}/maxresdefault.jpg`,
        thumbnail: `https://img.youtube.com/vi/${video.videoId}/default.jpg`,
      }))
    },
  },
  methods: {
    open(index) {
      this.$store.commit('showOverlay')
      const options = {
        slidesContainer: '.slides',
        onslide: this.onSlide,
        onclosed: this.onClose,
        youTubeClickToPlay: false,
        index,
      }
      const links = this.galleryVideos.concat(this.galleryImages)
      BlueimpGallery(links, options)
    },
    onClose() {
      this.$store.commit('hideOverlay')
    },
    onSlide(_index, _slide) {
      const activeSlide = document.querySelectorAll('.indicator li.active')[0]

      VueScrollTo.scrollTo(activeSlide, 300, {
        container: '.indicator',
        easing: 'ease-in-out',
        offset: -60,
        x: true,
        y: false,
      })
    },
  },
}
</script>
