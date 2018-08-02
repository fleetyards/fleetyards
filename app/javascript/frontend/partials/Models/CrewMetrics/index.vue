<template>
  <div class="row">
    <div
      v-if="title"
      :class="{
        'col-md-3': title,
      }"
      class="col-xs-12"
    >
      <div class="metrics-title">
        {{ t('labels.metrics.crew') }}
      </div>
    </div>
    <div
      :class="{
        'col-md-9': title,
      }"
      class="col-xs-12 metrics-block"
    >
      <div class="row">
        <div class="col-xs-6 col-sm-6">
          <div class="metrics-label">{{ t('model.minCrew') }}:</div>
          <div class="metrics-value">{{ toNumber(model.minCrew, 'people') }}</div>
        </div>
        <div
          class="col-xs-6 col-sm-6"
        >
          <div class="metrics-label">{{ t('model.maxCrew') }}:</div>
          <div class="metrics-value">{{ toNumber(model.maxCrew, 'people') }}</div>
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
    model: {
      type: Object,
      required: true,
    },
    title: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
