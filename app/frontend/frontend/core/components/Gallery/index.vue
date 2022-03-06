<template>
  <div class="pswp" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="pswp__bg" />
    <div class="pswp__scroll-wrap">
      <div class="pswp__container">
        <div class="pswp__item" />
        <div class="pswp__item" />
        <div class="pswp__item" />
      </div>
      <div class="pswp__ui pswp__ui--hidden">
        <div class="pswp__top-bar">
          <div class="pswp__counter" />
          <button
            class="pswp__button pswp__button--close"
            title="Close (Esc)"
          />
          <button class="pswp__button pswp__button--copy" @click="copyUrl">
            <i class="fa fa-copy" />
          </button>
          <button
            class="pswp__button pswp__button--fs"
            title="Toggle fullscreen"
          />
          <button class="pswp__button pswp__button--zoom" title="Zoom in/out" />
          <div class="pswp__preloader">
            <div class="pswp__preloader__icn">
              <div class="pswp__preloader__cut">
                <div class="pswp__preloader__donut" />
              </div>
            </div>
          </div>
        </div>
        <div
          class="pswp__share-modal pswp__share-modal--hidden pswp__single-tap"
        >
          <div class="pswp__share-tooltip" />
        </div>
        <button
          class="pswp__button pswp__button--arrow--left"
          title="Previous (arrow left)"
        />
        <button
          class="pswp__button pswp__button--arrow--right"
          title="Next (arrow right)"
        />
        <div class="pswp__caption">
          <div class="pswp__caption__center" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import PhotoSwipe from 'photoswipe'
import PhotoSwipeUIDefault from 'photoswipe/dist/photoswipe-ui-default'
import copyText from '@/frontend/utils/CopyText'
import { displaySuccess, displayAlert } from '@/frontend/lib/Noty'

export default {
  name: 'GalleryIndex',

  props: {
    items: {
      default() {
        return []
      },
      type: Array,
    },
  },
  data() {
    return {
      gallery: null,
      index: 0,
    }
  },

  computed: {
    galleryItems() {
      return this.items.map((item) => ({
        el: document.querySelector(`[href="${item.url}"]`),
        h: item.height,
        msrc: item.smallUrl,
        src: item.url,
        w: item.width,
      }))
    },

    options() {
      return {
        counterEl: false,
        getThumbBoundsFn: this.getThumbBounds,
        history: false,
        index: this.index,
        loop: true,
        shareEl: false,
        showHideOpacity: true,
      }
    },
  },

  methods: {
    copyUrl(_event) {
      copyText(this.gallery.currItem.src).then(
        () => {
          displaySuccess({
            text: this.$t('messages.copyImageUrl.success'),
          })
        },
        () => {
          displayAlert({
            text: this.$t('messages.copyImageUrl.failure'),
          })
        }
      )
    },

    getThumbBounds(index) {
      if (!this.galleryItems[index] || !this.galleryItems[index].el) {
        return { w: 0, x: 0, y: 0 }
      }

      const pageYScroll =
        window.pageYOffset || document.documentElement.scrollTop
      const rect = this.galleryItems[index].el.getBoundingClientRect()

      return { w: rect.width, x: rect.left, y: rect.top + pageYScroll }
    },

    onClose() {
      this.$store.dispatch('app/hideOverlay')
    },

    open(index = 0) {
      this.index = parseInt(index, 10)
      this.$store.dispatch('app/showOverlay')
      this.setup()
      this.gallery.init()
    },

    setup() {
      const pswpElement = document.querySelectorAll('.pswp')[0]

      this.gallery = new PhotoSwipe(
        pswpElement,
        PhotoSwipeUIDefault,
        this.galleryItems,
        this.options
      )

      this.gallery.listen('close', this.onClose)
    },
  },
}
</script>
