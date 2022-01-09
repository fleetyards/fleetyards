<template>
  <div
    class="row metrics-block top-metrics"
    :class="{
      'metrics-padding': padding,
    }"
  >
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
</template>

<script>
export default {
  name: 'ModelTopMetrics',

  props: {
    model: {
      type: Object,
      required: true,
    },

    padding: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    isGroundVehicle() {
      return this.model.classification === 'ground'
    },
    crew() {
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
        [minCrew, maxCrew].filter((item) => item).join(' - '),
        'people'
      )
    },

    speeds() {
      const speeds = []
      if (this.groundSpeeds || this.isGroundVehicle) {
        speeds.push(this.$toNumber(this.groundSpeeds, 'speed'))
      }
      if (!this.isGroundVehicle) {
        speeds.push(this.$toNumber(this.airSpeeds, 'speed'))
      }
      return speeds.join('<br>')
    },

    airSpeeds() {
      let { scmSpeed, afterburnerSpeed } = this.model

      if (scmSpeed && scmSpeed <= 0) {
        scmSpeed = null
      }

      if (afterburnerSpeed && afterburnerSpeed <= 0) {
        afterburnerSpeed = null
      }

      return [scmSpeed, afterburnerSpeed].filter((item) => item).join(' - ')
    },

    groundSpeeds() {
      let { groundSpeed, afterburnerGroundSpeed } = this.model

      if (groundSpeed && groundSpeed <= 0) {
        groundSpeed = null
      }

      if (afterburnerGroundSpeed && afterburnerGroundSpeed <= 0) {
        afterburnerGroundSpeed = null
      }

      return [groundSpeed, afterburnerGroundSpeed]
        .filter((item) => item)
        .join(' - ')
    },
  },
}
</script>
