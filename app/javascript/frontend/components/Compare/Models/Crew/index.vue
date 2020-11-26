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
          {{ $t('labels.metrics.crew') }}
          <i class="fa fa-chevron-right" />
        </div>
      </div>
      <div
        v-for="model in models"
        :key="`${model.slug}-placeholder`"
        class="col-12 compare-row-item"
      />
    </div>
    <BCollapse id="crew" :visible="visible">
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.minCrew') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.minCrew, 'people') }}
          </span>
        </div>
      </div>
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        >
          {{ $t('model.maxCrew') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.maxCrew, 'people') }}
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

@Component<ModelsCompareCrew>({
  components: {
    BCollapse,
  },
})
export default class ModelsCompareCrew extends Vue {
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
