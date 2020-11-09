<template>
  <div
    class="row"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ $t('labels.metrics.base') }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <div class="col-6">
          <div class="metrics-label">{{ $t('station.type') }}:</div>
          <div class="metrics-value">
            {{ station.typeLabel }}
          </div>
        </div>
        <div class="col-6">
          <div class="metrics-label">{{ $t('station.location') }}:</div>
          <LocationLabel class="metrics-value" :station="station" />
        </div>
      </div>
      <div class="row">
        <div class="col-6">
          <div class="metrics-label">{{ $t('station.refinary') }}:</div>
          <div class="metrics-value">
            {{ $t(`labels.${station.refinary}`) }}
          </div>
        </div>
        <div class="col-6">
          <div class="metrics-label">{{ $t('station.cargoHub') }}:</div>
          <div class="metrics-value">
            {{ $t(`labels.${station.cargoHub}`) }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import LocationLabel from 'frontend/components/Stations/LocationLabel'

export default {
  components: {
    LocationLabel,
  },

  props: {
    station: {
      type: Object,
      required: true,
    },

    padding: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
