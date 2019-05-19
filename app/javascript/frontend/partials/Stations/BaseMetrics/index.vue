<template>
  <div class="row">
    <div class="col-xs-12 col-md-3">
      <div class="metrics-title">
        {{ $t('labels.metrics.base') }}
      </div>
    </div>
    <div class="col-xs-12 col-md-9 metrics-block">
      <div class="row">
        <div class="col-xs-6">
          <div class="metrics-label">
            {{ $t('station.type') }}:
          </div>
          <div
            v-tooltip="station.typeLabel"
            class="metrics-value"
          >
            {{ station.typeLabel }}
          </div>
        </div>
        <div class="col-xs-6">
          <div class="metrics-label">
            {{ $t('station.location') }}:
          </div>
          <div
            v-tooltip="station.location"
            class="metrics-value"
          >
            {{ station.location }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    station: {
      type: Object,
      required: true,
    },
  },
}
</script>
