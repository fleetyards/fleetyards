<template>
  <div class="row metrics-padding">
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ $t('labels.metrics.crew') }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component<ModelCrewMetrics>({})
export default class ModelCrewMetrics extends Vue {
  @Prop({ required: true }) model: Model
}
</script>
