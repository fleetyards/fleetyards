<template>
  <Btn
    v-tooltip="!withLabel && $t('actions.saveScreenshot')"
    :loading="downloading"
    :aria-label="$t('actions.saveScreenshot')"
    :variant="variant"
    :size="size"
    :inline="inline"
    @click.native="download"
  >
    <SmallLoader :loading="downloading" />
    <i class="fad fa-image" />
    <span v-if="withLabel">
      {{ $t('actions.saveScreenshot') }}
    </span>
  </Btn>
</template>

<script>
import html2canvas from 'html2canvas'
import download from 'downloadjs'
import Btn from '@/frontend/core/components/Btn/index.vue'
import SmallLoader from '@/frontend/core/components/SmallLoader/index.vue'

export default {
  name: 'DownloadScreenshotBtn',

  components: {
    SmallLoader,
    Btn,
  },

  props: {
    element: {
      type: String,
      required: true,
    },

    withLabel: {
      type: Boolean,
      default: true,
    },

    filename: {
      type: String,
      default: 'fleetyards-screenshot',
    },
  },

  data() {
    return {
      downloading: false,
    }
  },

  methods: {
    async download() {
      this.downloading = true

      const element = document.querySelector(this.element)

      if (!element) {
        return
      }

      element.classList.add('fleetchart-download')

      html2canvas(element, {
        backgroundColor: null,
        useCORS: true,
        windowWidth: element.parentNode.scrollWidth,
        windowHeight: element.parentNode.scrollHeight + 100,
      })
        .then((canvas) => {
          element.classList.remove('fleetchart-download')
          this.downloading = false
          download(canvas.toDataURL(), `fleetyards-${this.filename}.png`)
        })
        .catch(() => {
          element.classList.remove('fleetchart-download')
          this.downloading = false
        })
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
