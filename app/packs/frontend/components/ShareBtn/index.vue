<template>
  <Btn
    v-tooltip="$t('actions.share')"
    :variant="variant"
    :size="size"
    :inline="inline"
    @click.native="share"
  >
    <i class="fad fa-share-square" />
  </Btn>
</template>

<script lang="ts">
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/core/components/Btn/index.vue'
import copyText from 'frontend/utils/CopyText'
import { displayAlert, displaySuccess } from 'frontend/lib/Noty'

@Component({
  components: {
    Btn,
  },
})
export default class ShareBtn extends Btn {
  @Prop({ required: true }) url!: string

  @Prop({ required: true }) title!: string

  share() {
    if (navigator.canShare && navigator.canShare({ url: this.url })) {
      navigator
        .share({
          title: this.title,
          url: this.url,
        })
        .then(() => console.info('Share was successful.'))
        .catch(error => console.info('Sharing failed', error))
    } else {
      this.copyShareUrl()
    }
  }

  copyShareUrl() {
    if (!this.url) {
      displayAlert({
        text: this.$t('messages.copyShareUrl.failure'),
      })
    }

    copyText(this.url).then(
      () => {
        displaySuccess({
          text: this.$t('messages.copyShareUrl.success', {
            url: this.url,
          }),
        })
      },
      () => {
        displayAlert({
          text: this.$t('messages.copyShareUrl.failure'),
        })
      },
    )
  }
}
</script>
