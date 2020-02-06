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
          @click="toggle"
        >
          {{ $t('labels.metrics.crew') }}
          <i class="fa fa-chevron-right" />
        </div>
      </div>
      <div
        v-for="model in models"
        :key="`${model.slug}-placeholder`"
        class="col-xs-12 compare-row-item"
      />
    </div>
    <b-collapse id="crew" :visible="visible">
      <div class="row compare-row">
        <div
          :style="{
            left: `${scrollLeft}px`,
          }"
          class="col-xs-12 compare-row-label text-right metrics-label"
        >
          {{ $t('model.minCrew') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-xs-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.minCrew, 'people') }}
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
          {{ $t('model.maxCrew') }}
        </div>
        <div
          v-for="model in models"
          :key="`${model.slug}-min-crew`"
          class="col-xs-6 text-center compare-row-item"
        >
          <span class="metrics-value">
            {{ $toNumber(model.maxCrew, 'people') }}
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
