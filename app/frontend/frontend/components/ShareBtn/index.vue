<template>
  <Btn
    v-tooltip="variant !== 'dropdown' && $t('actions.share')"
    :variant="variant"
    :size="size"
    :inline="inline"
    @click.native="share"
  >
    <i class="fad fa-share-square" />
    <span v-if="variant === 'dropdown'">{{ $t('actions.share') }}</span>
  </Btn>
</template>

<script>
import Btn from '@/frontend/core/components/Btn/index.vue'
import copyText from '@/frontend/utils/CopyText'
import { displayAlert, displaySuccess } from '@/frontend/lib/Noty'

export default {
  name: 'ShareBtn',

  components: {
    Btn,
  },

  props: {
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

    title: {
      type: String,
      required: true,
    },

    url: {
      type: String,
      required: true,
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
  },

  methods: {
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
        }
      )
    },

    share() {
      if (navigator.canShare && navigator.canShare({ url: this.url })) {
        navigator
          .share({
            title: this.title,
            url: this.url,
          })
          .then(() => console.info('Share was successful.'))
          .catch((error) => console.info('Sharing failed', error))
      } else {
        this.copyShareUrl()
      }
    },
  },
}
</script>
