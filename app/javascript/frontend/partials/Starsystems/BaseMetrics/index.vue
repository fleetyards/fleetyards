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
          <div class="metrics-label">{{ $t('starsystem.type') }}:</div>
          <div v-tooltip="starsystem.type" class="metrics-value">
            {{ starsystem.type }}
          </div>
        </div>
        <div class="col-6">
          <div class="metrics-label">{{ $t('starsystem.size') }}:</div>
          <div v-tooltip="starsystem.size" class="metrics-value">
            {{ $toAu(starsystem.size) }}
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

    padding: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
