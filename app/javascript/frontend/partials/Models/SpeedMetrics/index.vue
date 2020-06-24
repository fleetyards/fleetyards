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
        {{ $t('labels.metrics.speed') }}
      </div>
    </div>
    <div
      :class="{
        'col-lg-9': title,
      }"
      class="col-12 metrics-block"
    >
      <div v-if="!isGroundVehicle" class="row">
        <div class="col-6">
          <div class="metrics-label">{{ $t('model.scmSpeed') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.scmSpeed, 'speed') }}
          </div>
        </div>
        <div class="col-6">
          <div class="metrics-label">{{ $t('model.afterburnerSpeed') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.afterburnerSpeed, 'speed') }}
          </div>
        </div>
      </div>
      <div v-if="model.groundSpeed || model.afterburnerGroundSpeed" class="row">
        <div v-if="model.groundSpeed" class="col-6">
          <div class="metrics-label">{{ $t('model.groundSpeed') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.groundSpeed, 'speed') }}
          </div>
        </div>
        <div v-if="model.afterburnerGroundSpeed" class="col-6">
          <div class="metrics-label">
            {{ $t('model.afterburnerGroundSpeed') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(model.afterburnerGroundSpeed, 'speed') }}
          </div>
        </div>
      </div>
      <div v-if="!isGroundVehicle" class="row">
        <div class="col-12">
          <div class="seperator" />
        </div>
      </div>
      <div v-if="!isGroundVehicle" class="row">
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ $t('model.pitchMax') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.pitchMax, 'rotation') }}
          </div>
        </div>
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ $t('model.yawMax') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.yawMax, 'rotation') }}
          </div>
        </div>
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ $t('model.rollMax') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.rollMax, 'rotation') }}
          </div>
        </div>
      </div>
      <div v-if="!isGroundVehicle" class="row">
        <div class="col-12">
          <div class="seperator" />
        </div>
      </div>
      <div v-if="!isGroundVehicle" class="row">
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ $t('model.xaxisAcceleration') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.xaxisAcceleration, 'speed') }}
          </div>
        </div>
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ $t('model.yaxisAcceleration') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.yaxisAcceleration, 'speed') }}
          </div>
        </div>
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ $t('model.zaxisAcceleration') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.zaxisAcceleration, 'speed') }}
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
  computed: {
    isGroundVehicle() {
      return this.model.classification === 'ground'
    },
  },
}
</script>
