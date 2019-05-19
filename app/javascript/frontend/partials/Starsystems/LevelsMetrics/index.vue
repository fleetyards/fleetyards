<template>
  <div class="row">
    <div class="col-xs-12 col-md-3">
      <div class="metrics-title">
        {{ $t('labels.metrics.levels') }}
      </div>
    </div>
    <div class="col-xs-12 col-md-9 metrics-block">
      <div class="row">
        <div class="col-xs-4">
          <div class="metrics-label">
            {{ $t('starsystem.population') }}:
          </div>
          <div
            v-tooltip="starsystem.population"
            class="metrics-value"
          >
            {{ starsystem.population }}
          </div>
        </div>
        <div class="col-xs-4">
          <div class="metrics-label">
            {{ $t('starsystem.economy') }}:
          </div>
          <div
            v-tooltip="starsystem.economy"
            class="metrics-value"
          >
            {{ starsystem.economy }}
          </div>
        </div>
        <div class="col-xs-4">
          <div class="metrics-label">
            {{ $t('starsystem.danger') }}:
          </div>
          <div
            v-tooltip="starsystem.danger"
            class="metrics-value"
          >
            {{ starsystem.danger }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    starsystem: {
      type: Object,
      required: true,
    },
  },
}
</script>
