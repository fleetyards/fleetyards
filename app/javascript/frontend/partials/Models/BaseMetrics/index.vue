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
        {{ t('labels.metrics.base') }}
      </div>
    </div>
    <div
      :class="{
        'col-md-9': title,
      }"
      class="col-xs-12 metrics-block"
    >
      <div class="row">
        <div class="col-xs-6 col-md-4">
          <div class="metrics-label">{{ t('model.length') }}:</div>
          <div class="metrics-value">{{ toNumber(model.length, 'distance') }}</div>
          <div class="metrics-label">{{ t('model.beam') }}:</div>
          <div class="metrics-value">{{ toNumber(model.beam, 'distance') }}</div>
          <template v-if="detailed">
            <div class="metrics-label">{{ t('model.classification') }}:</div>
            <div class="metrics-value">{{ model.classificationLabel }}</div>
          </template>
        </div>
        <div class="col-xs-6 col-md-4">
          <div class="metrics-label">{{ t('model.height') }}:</div>
          <div class="metrics-value">{{ toNumber(model.height, 'distance') }}</div>
          <div class="metrics-label">{{ t('model.mass') }}:</div>
          <div class="metrics-value">{{ toNumber(model.mass, 'weight') }}</div>
        </div>
        <div class="col-xs-12 col-md-4">
          <div class="row">
            <div class="col-xs-6 col-md-12">
              <div class="metrics-label">{{ t('model.cargo') }}:</div>
              <div class="metrics-value">{{ toNumber(model.cargo, 'cargo') }}</div>
            </div>
            <div
              v-if="model.lastPrice"
              class="col-xs-6 col-md-12"
            >
              <div class="metrics-label">{{ t('model.lastPrice') }}:</div>
              <div class="metrics-value">{{ toDollar(model.lastPrice) }}</div>
            </div>
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
    model: {
      type: Object,
      required: true,
    },
    title: {
      type: Boolean,
      default: false,
    },
    detailed: {
      type: Boolean,
      default: false,
    },
  },
}
</script>
