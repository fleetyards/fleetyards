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
    <template v-if="withLabel">
      <template v-if="showStatus">
        {{ $t('actions.hideStatusColor') }}
      </template>
      <template v-else>
        {{ $t('actions.showStatusColor') }}
      </template>
    </template>
  </Btn>
</template>

<script lang="ts">
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/core/components/Btn/index.vue'

@Component<FleetChartStatusBtn>({
  components: {
    Btn,
  },
})
export default class FleetChartStatusBtn extends Btn {
  @Prop({ default: true }) withLabel!: boolean

  showStatus: boolean = false

  mounted() {
    this.showStatus = !!this.$route.query?.showStatus

    this.$comlink.$on('fleetchart-toggle-status', this.setShowStatus)
  }

  beforeDestroy() {
    this.$comlink.$off('fleetchart-toggle-status')
  }

  setShowStatus() {
    this.showStatus = !this.showStatus
  }

  toggleStatus() {
    this.$comlink.$emit('fleetchart-toggle-status')
  }
}
</script>
