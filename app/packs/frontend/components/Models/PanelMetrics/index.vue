<template>
  <div>
    <div class="row metrics-block top-metrics metrics-padding">
      <div v-if="model.focus" class="col-6 col-md-4">
        <div class="metrics-label">{{ $t('model.focus') }}:</div>
        <div class="metrics-value">
          {{ model.focus }}
        </div>
      </div>
      <div v-if="model.minCrew || model.maxCrew" class="col-6 col-md-4">
        <div class="metrics-label">{{ $t('model.crew') }}:</div>
        <div class="metrics-value">
          {{ crew }}
        </div>
      </div>
      <div class="col-12 col-md-4">
        <div class="metrics-label">{{ $t('model.speed') }}:</div>
        <div class="metrics-value" v-html="speeds" />
      </div>
    </div>

    <hr class="dark slim-spacer" />

    <div class="row base-metrics metrics-padding">
      <div class="col-12 metrics-block">
        <div class="row">
          <div class="col-6 col-lg-4">
            <div class="metrics-label">{{ $t('model.length') }}:</div>
            <div class="metrics-value">
              {{ $toNumber(model.length, 'distance') }}
            </div>
            <div class="metrics-label">{{ $t('model.beam') }}:</div>
            <div class="metrics-value">
              {{ $toNumber(model.beam, 'distance') }}
            </div>
          </div>
          <div class="col-6 col-lg-4">
            <div class="metrics-label">{{ $t('model.height') }}:</div>
            <div class="metrics-value">
              {{ $toNumber(model.height, 'distance') }}
            </div>
            <div class="metrics-label">{{ $t('model.mass') }}:</div>
            <div class="metrics-value">
              {{ $toNumber(model.mass, 'weight') }}
            </div>
          </div>
          <div class="col-12 col-lg-4">
            <div class="row">
              <div class="col-6 col-lg-12">
                <div class="metrics-label">{{ $t('model.cargo') }}:</div>
                <div class="metrics-value">
                  {{ $toNumber(model.cargo, 'cargo') }}
                </div>
              </div>
              <div v-if="model.price" class="col-6 col-lg-12">
                <div class="metrics-label">{{ $t('model.price') }}:</div>
                <div
                  v-tooltip="$toUEC(model.price)"
                  class="metrics-value"
                  v-html="$toUEC(model.price)"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component<PanelMetrics>({})
export default class PanelMetrics extends Vue {
  @Prop({ required: true }) model: Model

  get isGroundVehicle() {
    return this.model.classification === 'ground'
  }

  get crew() {
    let { minCrew, maxCrew } = this.model

    if (minCrew && minCrew <= 0) {
      minCrew = null
    }

    if (maxCrew && maxCrew <= 0) {
      maxCrew = null
    }

    if (minCrew === maxCrew) {
      return this.$toNumber(this.model.minCrew, 'people')
    }

    return this.$toNumber(
      [minCrew, maxCrew].filter(item => item).join(' - '),
      'people',
    )
  }

  get speeds() {
    const speeds = []
    if (this.groundSpeeds || this.isGroundVehicle) {
      speeds.push(this.$toNumber(this.groundSpeeds, 'speed'))
    }
    if (!this.isGroundVehicle) {
      speeds.push(this.$toNumber(this.airSpeeds, 'speed'))
    }
    return speeds.join('<br>')
  }

  get airSpeeds() {
    let { scmSpeed, afterburnerSpeed } = this.model

    if (scmSpeed && scmSpeed <= 0) {
      scmSpeed = null
    }

    if (afterburnerSpeed && afterburnerSpeed <= 0) {
      afterburnerSpeed = null
    }

    return [scmSpeed, afterburnerSpeed].filter(item => item).join(' - ')
  }

  get groundSpeeds() {
    let { groundSpeed, afterburnerGroundSpeed } = this.model

    if (groundSpeed && groundSpeed <= 0) {
      groundSpeed = null
    }

    if (afterburnerGroundSpeed && afterburnerGroundSpeed <= 0) {
      afterburnerGroundSpeed = null
    }

    return [groundSpeed, afterburnerGroundSpeed]
      .filter(item => item)
      .join(' - ')
  }
}
</script>
