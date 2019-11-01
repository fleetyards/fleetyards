<template>
  <div
    :class="{
      'metrics-padding': padding,
    }"
  >
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
              {{ $t('celestialObject.type') }}:
            </div>
            <div
              v-tooltip="celestialObject.type"
              class="metrics-value"
            >
              {{ celestialObject.type }}
            </div>
          </div>
          <div class="col-xs-6">
            <div class="metrics-label">
              {{ $t('celestialObject.subType') }}:
            </div>
            <div
              v-tooltip="celestialObject.subType"
              class="metrics-value"
            >
              {{ celestialObject.subType }}
            </div>
          </div>
          <div class="col-xs-6">
            <div class="metrics-label">
              {{ $t('celestialObject.habitable') }}:
            </div>
            <div
              v-tooltip="celestialObject.habitable"
              class="metrics-value"
            >
              {{ $t(`labels.${!!celestialObject.habitable}`) }}
            </div>
          </div>
          <div class="col-xs-6">
            <div class="metrics-label">
              {{ $t('celestialObject.fairchanceakt') }}:
            </div>
            <div
              v-tooltip="celestialObject.fairchanceakt"
              class="metrics-value"
            >
              {{ $t(`labels.${!!celestialObject.fairchanceakt}`) }}
            </div>
          </div>
        </div>
      </div>
    </div>
    <br>
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
              {{ $t('celestialObject.population') }}:
            </div>
            <div
              v-tooltip="celestialObject.population"
              class="metrics-value"
            >
              {{ celestialObject.population }}
            </div>
          </div>
          <div class="col-xs-4">
            <div class="metrics-label">
              {{ $t('celestialObject.economy') }}:
            </div>
            <div
              v-tooltip="celestialObject.economy"
              class="metrics-value"
            >
              {{ celestialObject.economy }}
            </div>
          </div>
          <div class="col-xs-4">
            <div class="metrics-label">
              {{ $t('celestialObject.danger') }}:
            </div>
            <div
              v-tooltip="celestialObject.danger"
              class="metrics-value"
            >
              {{ celestialObject.danger }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    celestialObject: {
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
