<template>
  <div>
    <div class="row compare-row compare-section">
      <div class="col-12 compare-row-label sticky-left">
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
          class="col-12 compare-row-label text-right metrics-label sticky-left"
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
          class="col-12 compare-row-label text-right metrics-label sticky-left"
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
          class="col-12 compare-row-label text-right metrics-label sticky-left"
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
          class="col-12 compare-row-label text-right metrics-label sticky-left"
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
          class="col-12 compare-row-label text-right metrics-label sticky-left"
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
          class="col-12 compare-row-label text-right metrics-label sticky-left"
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
          class="col-12 compare-row-label text-right metrics-label sticky-left"
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
          class="col-12 compare-row-label text-right metrics-label sticky-left"
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
          class="col-12 compare-row-label text-right metrics-label sticky-left"
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
          class="col-12 compare-row-label text-right metrics-label sticky-left"
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
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.price') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-cargo`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value" v-html="$toUEC(model.price)" />
        </div>
      </div>
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import { BCollapse } from 'bootstrap-vue'

@Component<ModelsCompareBase>({
  components: {
    BCollapse,
  },
})
export default class ModelsCompareBase extends Vue {
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
