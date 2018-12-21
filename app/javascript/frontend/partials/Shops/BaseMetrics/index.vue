<template>
  <div class="row">
    <div class="col-xs-12 col-md-3">
      <div class="metrics-title">
        {{ t('labels.metrics.info') }}
      </div>
    </div>
    <div class="col-xs-12 col-md-9 metrics-block">
      <div class="row">
        <div class="col-xs-6">
          <div class="metrics-label">
            {{ t('shop.type') }}:
          </div>
          <div
            v-tooltip="shop.typeLabel"
            class="metrics-value"
          >
            {{ shop.typeLabel }}
          </div>
        </div>
      </div>
      <div class="row">
        <div class="col-xs-6">
          <div class="metrics-label">
            {{ t('shop.celestialObject') }}:
          </div>
          <div
            v-tooltip="shop.celestialObject.name"
            class="metrics-value"
          >
            {{ shop.celestialObject.name }}
          </div>
        </div>
        <div class="col-xs-6">
          <div class="metrics-label">
            {{ t('shop.station') }}:
          </div>
          <div
            v-tooltip="shop.station.name"
            class="metrics-value"
          >
            {{ shop.station.name }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'

export default {
  mixins: [I18n],
  props: {
    shop: {
      type: Object,
      required: true,
    },
  },
}
</script>
