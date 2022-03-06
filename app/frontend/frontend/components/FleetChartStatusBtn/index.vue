<template>
  <Btn
    v-tooltip="!withLabel && $t('actions.showStatusColor')"
    :aria-label="$t('actions.showStatusColor')"
    :variant="variant"
    :size="size"
    :inline="inline"
    @click.native="toggleStatus"
  >
    <i
      class="fad"
      :class="{
        'fa-star-half-alt': !showStatus,
        'fa-star': showStatus,
      }"
    />
    <span v-if="withLabel">
      <template v-if="showStatus">
        {{ $t('actions.hideStatusColor') }}
      </template>
      <template v-else>
        {{ $t('actions.showStatusColor') }}
      </template>
    </span>
  </Btn>
</template>

<script>
import Btn from '@/frontend/core/components/Btn/index.vue'

export default {
  name: 'FleetChartStatusBtn',

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
      showStatus: false,
    }
  },

  beforeDestroy() {
    this.$comlink.$off('fleetchart-toggle-status')
  },

  mounted() {
    this.showStatus = !!this.$route.query?.showStatus

    this.$comlink.$on('fleetchart-toggle-status', this.setShowStatus)
  },

  methods: {
    setShowStatus() {
      this.showStatus = !this.showStatus
    },

    toggleStatus() {
      this.$comlink.$emit('fleetchart-toggle-status')
    },
  },
}
</script>
