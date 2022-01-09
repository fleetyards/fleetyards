<template>
  <div
    class="row"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ $t('labels.metrics.levels') }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <div class="col-4">
          <div class="metrics-label">{{ $t('starsystem.population') }}:</div>
          <div v-tooltip="starsystem.population" class="metrics-value">
            {{ starsystem.population }}
          </div>
        </div>
        <div class="col-4">
          <div class="metrics-label">{{ $t('starsystem.economy') }}:</div>
          <div v-tooltip="starsystem.economy" class="metrics-value">
            {{ starsystem.economy }}
          </div>
        </div>
        <div class="col-4">
          <div class="metrics-label">{{ $t('starsystem.danger') }}:</div>
          <div v-tooltip="starsystem.danger" class="metrics-value">
            {{ starsystem.danger }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'StarsystemsLevelsMetrics',

  props: {
    starsystem: {
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
