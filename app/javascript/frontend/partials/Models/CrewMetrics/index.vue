<template>
  <div
    class="row"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div
      v-if="title"
      :class="{
        'col-lg-3': title,
      }"
      class="col-12"
    >
      <div class="metrics-title">
        {{ $t('labels.metrics.crew') }}
      </div>
    </div>
    <div
      :class="{
        'col-lg-9': title,
      }"
      class="col-12 metrics-block"
    >
      <div class="row">
        <div class="col-6 col-md-6">
          <div class="metrics-label">{{ $t('model.minCrew') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.minCrew, 'people') }}
          </div>
        </div>
        <div class="col-6 col-md-6">
          <div class="metrics-label">{{ $t('model.maxCrew') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.maxCrew, 'people') }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    model: {
      type: Object,
      required: true,
    },

    title: {
      type: Boolean,
      default: false,
    },

    padding: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
