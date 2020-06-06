<template>
  <Btn
    v-tooltip="showTooltip && $t('actions.saveScreenshot')"
    :loading="downloading"
    :aria-label="$t('actions.saveScreenshot')"
    :variant="variant"
    :size="size"
    :inline="inline"
    @click.native="download"
  >
    <SmallLoader :loading="downloading" />
    <span
      :class="{
        active: downloading,
      }"
      class="text"
    >
      <i class="fad fa-image" />
      {{ $t('actions.saveScreenshot') }}
    </span>
  </Btn>
</template>

<script lang="ts">
import { Component, Prop } from 'vue-property-decorator'
import html2canvas from 'html2canvas'
import download from 'downloadjs'
import Btn from 'frontend/components/Btn/index.vue'
import SmallLoader from 'frontend/components/SmallLoader/index.vue'

@Component({
  components: {
    SmallLoader,
    Btn,
  },
})
export default class DownloadScreenshotBtn extends Btn {
  @Prop({ required: true }) element!: string

  @Prop({ default: true }) showTooltip!: boolean

  @Prop({ default: 'fleetyards-screenshot' }) filename!: string

  downloading: boolean = false

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
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
