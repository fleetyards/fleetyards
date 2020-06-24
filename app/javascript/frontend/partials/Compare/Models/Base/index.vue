<template>
  <div>
    <div class="row compare-row compare-section">
      <div
        :style="{
          left: `${scrollLeft}px`,
        }"
        class="col-12 compare-row-label"
      >
        <div
          :class="{
            active: visible,
          }"
          class="text-right metrics-title"
          @click="toggle"
        >
          {{ $t('labels.metrics.base') }}
          <i class="fa fa-chevron-right" />
        </div>
      </div>
      <div
        v-for="model in models"
        :key="`${model.slug}-placeholder`"
        class="col-12 compare-row-item"
      />
    </div>
    <BCollapse id="base" :visible="visible">
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.manufacturer') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-manufacturer`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value" v-html="model.manufacturer.name" />
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.productionStatus') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-production-status`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $t(`labels.model.productionStatus.${model.productionStatus}`) }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.focus') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-focus`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ model.focus }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.classification') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-classification`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ model.classificationLabel }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.size') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-size`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ model.sizeLabel }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.length') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-length`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.length, 'distance') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.beam') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-beam`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.beam, 'distance') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.height') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-height`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.height, 'distance') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.mass') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-mass`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.mass, 'weight') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.cargo') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-cargo`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.cargo, 'cargo') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.price') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-cargo`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toUEC(model.price) }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.pledgePrice') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-cargo`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toDollar(model.lastPledgePrice) }}
          </span>
        </div>
      </div>
    </BCollapse>
  </div>
</template>

<script>
import { BCollapse } from 'bootstrap-vue'

export default {
  components: {
    BCollapse,
  },

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
