<template>
  <div
    class="fleetchart-item fade-list-item"
    :style="{
      'min-height': `${height}px`,
    }"
    :class="cssClasses"
  >
    <div v-if="showLabel" class="fleetchart-item-label">
      <template v-if="name">
        <span>{{ name }}</span>
        <small>
          <span>{{ modelName }}</span>
          <template v-if="showStatus"><br />{{ productionStatus }}</template>
        </small>
      </template>
      <template v-else>
        <span>{{ modelName }}</span>
        <small v-if="showStatus">
          {{ productionStatus }}
        </small>
      </template>
    </div>
    <div
      class="fleetchart-item-image-wrapper"
      :style="{
        width: `${length}px`,
        height: `${height}px`,
      }"
    >
      <FleetchartItemImage
        :label="name || modelName"
        :src="image"
        :width="imageWidth"
        :height="height"
      />
    </div>
  </div>
</template>

<script>
import FleetchartItemImage from './Image/index.vue'

export default {
  name: 'FleetchartListItem',

  components: {
    FleetchartItemImage,
  },

  props: {
    item: {
      type: Object,
      required: true,
    },

    scale: {
      type: Number,
      default: 1,
    },

    showLabel: {
      type: Boolean,
      default: false,
    },

    showStatus: {
      type: Boolean,
      default: false,
    },

    sizeMultiplicator: {
      type: Number,
      default: 1,
    },

    viewpoint: {
      type: String,
      default: 'side',
    },
  },

  computed: {
    cssClasses() {
      const cssClasses = [`fleetchart-item-${this.model.slug}`]

      if (this.showStatus) {
        cssClasses.push(`status-${this.model.productionStatus}`)
      }

      if (this.showLabel) {
        cssClasses.push('fleetchart-item-with-labels')
      }

      return cssClasses
    },

    height() {
      return (
        (this.length * this.sourceImageHeightMax) / this.sourceImageWidthMax
      )
    },

    image() {
      if (
        this.modulePackage &&
        (this.modulePackage.topView ||
          this.modulePackage.sideView ||
          this.modulePackage.angledView)
      ) {
        const url = this.extractImageFromModel(this.modulePackage)
        if (url) {
          return url
        }
      }

      if (
        this.paint &&
        (this.paint.topView || this.paint.sideView || this.paint.angledView)
      ) {
        const url = this.extractImageFromModel(this.paint)
        if (url) {
          return url
        }
      }

      return this.extractImageFromModel(this.model)
    },

    imageWidth() {
      return Math.min(
        (this.height * this.sourceImageWidth) / this.sourceImageHeight,
        this.length
      )
    },

    length() {
      return this.model.fleetchartLength * this.sizeMultiplicator
    },

    model() {
      if (this.item && this.item.model) {
        return this.item.model
      }

      return this.item
    },

    modelName() {
      if (this.paint && this.paint.rsiId) {
        return `${this.model.manufacturer.code} ${this.paint.name}`
      }

      return `${this.model.manufacturer.code} ${this.model.name}`
    },

    modulePackage() {
      if (this.vehicle && this.vehicle.modulePackage) {
        return this.vehicle.modulePackage
      }

      return null
    },

    name() {
      if (this.vehicle && this.vehicle.name) {
        return this.vehicle.name
      }

      return null
    },

    paint() {
      if (this.vehicle && this.vehicle.paint) {
        return this.vehicle.paint
      }

      return null
    },

    productionStatus() {
      return this.$t(
        `labels.model.productionStatus.${this.model.productionStatus}`
      )
    },

    sourceImageHeight() {
      if (
        this.modulePackage &&
        (this.modulePackage.topView ||
          this.modulePackage.sideView ||
          this.modulePackage.angledView)
      ) {
        const height = this.extractImageHeightFromModel(this.modulePackage)
        if (height) {
          return height
        }
      }

      if (
        this.paint &&
        (this.paint.topView || this.paint.sideView || this.paint.angledView)
      ) {
        const height = this.extractImageHeightFromModel(this.paint)
        if (height) {
          return height
        }
      }

      return this.extractImageHeightFromModel(this.model)
    },

    sourceImageHeightMax() {
      if (
        this.modulePackage &&
        (this.modulePackage.topView ||
          this.modulePackage.sideView ||
          this.modulePackage.angledView)
      ) {
        const height = this.extractMaxHeightFromModel(this.modulePackage)
        if (height) {
          return height
        }
      }

      if (
        this.paint &&
        (this.paint.topView || this.paint.sideView || this.paint.angledView)
      ) {
        const height = this.extractMaxHeightFromModel(this.paint)
        if (height) {
          return height
        }
      }

      return this.extractMaxHeightFromModel(this.model)
    },

    sourceImageWidth() {
      if (
        this.modulePackage &&
        (this.modulePackage.topView ||
          this.modulePackage.sideView ||
          this.modulePackage.angledView)
      ) {
        const height = this.extractImageWidthFromModel(this.modulePackage)
        if (height) {
          return height
        }
      }

      if (
        this.paint &&
        (this.paint.topView || this.paint.sideView || this.paint.angledView)
      ) {
        const width = this.extractImageWidthFromModel(this.paint)
        if (width) {
          return width
        }
      }

      return this.extractImageWidthFromModel(this.model)
    },

    sourceImageWidthMax() {
      if (
        this.modulePackage &&
        (this.modulePackage.topView ||
          this.modulePackage.sideView ||
          this.modulePackage.angledView)
      ) {
        const width = this.extractMaxWidthFromModel(this.modulePackage)
        if (width) {
          return width
        }
      }

      if (
        this.paint &&
        (this.paint.topView || this.paint.sideView || this.paint.angledView)
      ) {
        const width = this.extractMaxWidthFromModel(this.paint)
        if (width) {
          return width
        }
      }

      return this.extractMaxWidthFromModel(this.model)
    },

    tooltip() {
      if (this.showStatus) {
        return `${this.label}<small>${this.productionStatus}`
      }

      return this.label
    },

    vehicle() {
      if (this.item && this.item.model) {
        return this.item
      }

      return null
    },

    viewpointAngled() {
      return this.viewpoint === 'angled'
    },

    viewpointSide() {
      return this.viewpoint === 'side'
    },

    viewpointTop() {
      return this.viewpoint === 'top'
    },
  },

  methods: {
    angledView(model) {
      const width = this.length * this.sizeMultiplicator * this.scale

      if (width > 1900) {
        return model.angledView
      }

      if (width > 900) {
        return model.angledViewLarge
      }

      return model.angledViewMedium
    },

    extractImageFromModel(model) {
      if (this.viewpointTop && model.topView) {
        return this.topView(model)
      }

      if (this.viewpointSide && model.sideView) {
        return this.sideView(model)
      }

      if (this.viewpointAngled && model.angledView) {
        return this.angledView(model)
      }

      return null
    },

    extractImageHeightFromModel(model) {
      if (this.viewpointTop && model.topView) {
        return model.topViewHeight
      }

      if (this.viewpointSide && model.sideView) {
        return model.sideViewHeight
      }

      if (this.viewpointAngled && model.angledView) {
        return model.angledViewHeight
      }

      return null
    },

    extractImageWidthFromModel(model) {
      if (this.viewpointTop && model.topView) {
        return model.topViewWidth
      }

      if (this.viewpointSide && model.sideView) {
        return model.sideViewWidth
      }

      if (this.viewpointAngled && model.angledView) {
        return model.angledViewWidth
      }

      return null
    },

    extractMaxHeightFromModel(model) {
      return Math.max(
        model.topViewHeight,
        model.sideViewHeight,
        model.angledViewHeight
      )
    },

    extractMaxWidthFromModel(model) {
      return Math.max(
        model.topViewWidth,
        model.sideViewWidth,
        model.angledViewWidth
      )
    },

    sideView(model) {
      const width = this.length * this.sizeMultiplicator * this.scale

      if (width > 1900) {
        return model.sideView
      }

      if (width > 900) {
        return model.sideViewLarge
      }

      return model.sideViewMedium
    },

    topView(model) {
      const width = this.length * this.sizeMultiplicator * this.scale

      if (width > 1900) {
        return model.topView
      }

      if (width > 900) {
        return model.topViewLarge
      }

      return model.topViewMedium
    },
  },
}
</script>
