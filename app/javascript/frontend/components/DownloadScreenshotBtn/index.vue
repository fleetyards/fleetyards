<template>
  <Btn
    v-tooltip="t('actions.saveScreenshot')"
    :disabled="downloading"
    :aria-label="t('actions.saveScreenshot')"
    small
    @click.native="download"
  >
    <SmallLoader :loading="downloading" />
    <span
      :class="{
        active: downloading
      }"
      class="text"
    >
      {{ t('actions.saveScreenshot') }}
    </span>
  </Btn>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import html2canvas from 'html2canvas'
import download from 'downloadjs'
import Btn from 'frontend/components/Btn'
import SmallLoader from 'frontend/components/SmallLoader'

export default {
  components: {
    SmallLoader,
    Btn,
  },
  mixins: [I18n],
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
      html2canvas(document.querySelector(this.element), {
        backgroundColor: null,
        useCORS: true,
      }).then((canvas) => {
        this.downloading = false
        download(canvas.toDataURL(), `fleetyards-${this.filename}.png`)
      })
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
