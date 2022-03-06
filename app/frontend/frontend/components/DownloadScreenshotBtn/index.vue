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
    Btn,
    SmallLoader,
  },

  props: {
    element: {
      type: String,
      required: true,
    },

    filename: {
      type: String,
      default: 'fleetyards-screenshot',
    },

    inline: {
      type: Boolean,
      default: false,
    },

    size: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'small', 'large'].indexOf(value) !== -1
      },
    },

    variant: {
      type: String,
      default: 'default',
      validator(value) {
        return (
          ['default', 'transparent', 'link', 'danger', 'dropdown'].indexOf(
            value
          ) !== -1
        )
      },
    },

    withLabel: {
      type: Boolean,
      default: true,
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
        windowHeight: element.parentNode.scrollHeight + 100,
        windowWidth: element.parentNode.scrollWidth,
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
