<template>
  <div>
    <div class="row compare-row compare-section">
      <div class="col-12 compare-row-label sticky-left">
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
        class="col-12 compare-row-item"
      />
    </div>
    <BCollapse id="speed" :visible="visible">
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.scmSpeed') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.scmSpeed, 'speed') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.afterburnerSpeed') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.afterburnerSpeed, 'speed') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.groundSpeed') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.groundSpeed, 'speed') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.afterburnerGroundSpeed') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.afterburnerGroundSpeed, 'speed') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.pitchMax') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.pitchMax, 'rotation') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.yawMax') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.yawMax, 'rotation') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.rollMax') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.rollMax, 'rotation') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.xaxisAcceleration') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.xaxisAcceleration, 'speed') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.yaxisAcceleration') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.yaxisAcceleration, 'speed') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.zaxisAcceleration') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.zaxisAcceleration, 'speed') }}
          </span>
        </div>
      </div>
    </BCollapse>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import { BCollapse } from 'bootstrap-vue'

@Component<ModelsCompareSpeed>({
  components: {
    BCollapse,
  },
})
export default class ModelsCompareSpeed extends Vue {
  @Prop({ required: true }) models!: Model[]

  visible: boolean = false

  mounted() {
    this.visible = this.models.length > 0
  }

  @Watch('models')
  onModelsChange() {
    this.visible = this.models.length > 0
  }

  toggle() {
    this.visible = !this.visible
  }
}
</script>
