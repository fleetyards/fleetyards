<template>
  <Btn
    v-tooltip="$t('actions.saveScreenshot')"
    :loading="downloading"
    :aria-label="$t('actions.saveScreenshot')"
    size="small"
    @click.native="download"
  >
    <SmallLoader :loading="downloading" />
    <span
      :class="{
        active: downloading,
      }"
      class="text"
    >
      {{ $t('actions.saveScreenshot') }}
    </span>
  </Btn>
</template>

<script>
import html2canvas from 'html2canvas'
import download from 'downloadjs'
import Btn from 'frontend/components/Btn'
import SmallLoader from 'frontend/components/SmallLoader'

export default {
  components: {
    SmallLoader,
    Btn,
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
  },
  data() {
    return {
      downloading: false,
    }
  },
  methods: {
    download() {
      this.downloading = true

      const element = document.querySelector(this.element)
      element.classList.add('fleetchart-download')

      html2canvas(element, {
        backgroundColor: null,
        useCORS: true,
      })
        .then(canvas => {
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
