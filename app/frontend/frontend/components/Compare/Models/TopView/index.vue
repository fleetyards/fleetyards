<template>
  <div ref="compareTopView">
    <div class="row compare-row compare-section">
      <div class="col-12 compare-row-label sticky-left">
        <div
          :class="{
            active: visible,
          }"
          class="text-right metrics-title"
          @click="toggle"
        >
          {{ $t('labels.metrics.topView') }}
          <i class="fa fa-chevron-right" />
        </div>
      </div>
      <div
        v-for="model in models"
        :key="`${model.slug}-placeholder`"
        class="col-12 compare-row-item"
      />
    </div>
    <BCollapse id="topView" :visible="visible">
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        />
        <div
          v-for="model in models"
          :key="`${model.slug}-top-view`"
          class="col-6 text-center compare-row-item compare-row-item-top-view"
        >
          <FleetchartItemImage
            :label="model.name"
            :src="model.sideViewSmall"
            :width="length(model)"
          />
        </div>
      </div>
      <div class="row compare-row">
        <div
          class="col-12 compare-row-label text-right metrics-label sticky-left"
        />
        <div
          v-for="model in models"
          :key="`${model.slug}-top-view`"
          class="col-6 text-center compare-row-item compare-row-item-top-view"
        >
          <FleetchartItemImage
            :label="model.name"
            :src="model.topViewSmall"
            :width="length(model)"
          />
        </div>
      </div>
    </BCollapse>
  </div>
</template>

<script>
import { BCollapse } from 'bootstrap-vue'
import FleetchartItemImage from '@/frontend/components/Fleetchart/List/Item/Image'

export default {
  name: 'ModelsCompareTopView',

  components: {
    BCollapse,
    FleetchartItemImage,
  },

  props: {
    models: {
      type: Array,
      required: true,
    },
  },

  data() {
    return {
      visible: false,
    }
  },

  computed: {
    maxWidth() {
      if (!this.$refs.compareTopView) {
        return 0
      }

      return this.$refs.compareTopView.offsetWidth / 4
    },

    scale() {
      if (this.models.length <= 0) {
        return 0
      }

      const maxLength = Math.max(
        ...this.models.map((model) => model.fleetchartLength),
        0
      )

      return this.maxWidth / (maxLength * 3)
    },
  },

  watch: {
    models() {
      this.visible = this.models.length > 0
    },
  },

  mounted() {
    this.visible = this.models.length > 0
  },

  methods: {
    length(model) {
      return model.fleetchartLength * 3 * this.scale
    },

    toggle() {
      this.visible = !this.visible
    },
  },
}
</script>
