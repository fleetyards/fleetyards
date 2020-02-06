<template>
  <div>
    <div class="row compare-row compare-section">
      <div
        :style="{
          left: `${scrollLeft}px`,
        }"
        class="col-xs-12 compare-row-label"
      >
        <div
          :class="{
            active: visible,
          }"
          class="text-right metrics-title"
          @click="toggle('speed')"
        >
          {{ $t('labels.metrics.speed') }}
          <i class="fa fa-chevron-right" />
        </div>
      </div>
      <div
        v-for="model in models"
        :key="`${model.slug}-placeholder`"
        class="col-xs-12 compare-row-item"
      />
    </div>
    <b-collapse id="speed" :visible="visible">
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-xs-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.scmSpeed') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-xs-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.scmSpeed, 'speed') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-xs-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.afterburnerSpeed') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-xs-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.afterburnerSpeed, 'speed') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-xs-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.groundSpeed') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-xs-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.groundSpeed, 'speed') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-xs-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.afterburnerGroundSpeed') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-xs-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.afterburnerGroundSpeed, 'speed') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-xs-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.pitchMax') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-xs-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.pitchMax, 'rotation') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-xs-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.yawMax') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-xs-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.yawMax, 'rotation') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-xs-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.rollMax') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-xs-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.rollMax, 'rotation') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-xs-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.xaxisAcceleration') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-xs-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.xaxisAcceleration, 'speed') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-xs-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.yaxisAcceleration') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-xs-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.yaxisAcceleration, 'speed') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-xs-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.zaxisAcceleration') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-xs-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.zaxisAcceleration, 'speed') }}
          </span>
        </div>
      </div>
    </b-collapse>
  </div>
</template>

<script>
export default {
  props: {
    models: {
      type: Array,
      required: true,
    },

    scrollLeft: {
      type: Number,
      required: true,
    },
  },

  data() {
    return {
      visible: this.models.length > 0,
    }
  },

  watch: {
    models() {
      this.visible = this.models.length > 0
    },
  },

  methods: {
    toggle() {
      this.visible = !this.visible
    },
  },
}
</script>
