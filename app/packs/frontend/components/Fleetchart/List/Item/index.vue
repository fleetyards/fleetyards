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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/core/components/Btn/index.vue'
import FleetchartItemImage from './Image'

@Component({
  components: {
    Btn,
    FleetchartItemImage,
  },
})
export default class FleetchartListItem extends Vue {
  @Prop({ required: true }) item!: Model | Vehicle

  @Prop({ default: 'side' }) viewpoint!: string

  @Prop({ default: false }) showLabel!: boolean

  @Prop({ default: false }) showStatus!: boolean

  @Prop({ default: 1 }) sizeMultiplicator!: number

  @Prop({ default: 1 }) scale!: number

  get cssClasses() {
    const cssClasses = [`fleetchart-item-${this.model.slug}`]

    if (this.showStatus) {
      cssClasses.push(`status-${this.model.productionStatus}`)
    }

    if (this.showLabel) {
      cssClasses.push('fleetchart-item-with-labels')
    }

    return cssClasses
  }

  get model() {
    if (this.item && this.item.model) {
      return this.item.model
    }

    return this.item
  }

  get vehicle() {
    if (this.item && this.item.model) {
      return this.item
    }

    return null
  }

  get paint() {
    if (this.vehicle && this.vehicle.paint) {
      return this.vehicle.paint
    }

    return null
  }

  get image() {
    if (this.paint && (this.paint.topView || this.paint.sideView)) {
      if (this.viewpointTop && this.paint.topView) {
        return this.topView(this.paint)
      }

      if (this.viewpointSide && this.paint.sideView) {
        return this.sideView(this.paint)
      }

      if (this.viewpointAngled && this.paint.angledView) {
        return this.angledView(this.paint)
      }
    }

    if (this.viewpointTop && this.model.topView) {
      return this.topView(this.model)
    }

    if (this.viewpointSide && this.model.sideView) {
      return this.sideView(this.model)
    }

    if (this.viewpointAngled && this.model.angledView) {
      return this.angledView(this.model)
    }

    return null
  }

  get viewpointTop() {
    return this.viewpoint === 'top'
  }

  get viewpointSide() {
    return this.viewpoint === 'side'
  }

  get viewpointAngled() {
    return this.viewpoint === 'angled'
  }

  get productionStatus() {
    return this.$t(
      `labels.model.productionStatus.${this.model.productionStatus}`
    )
  }

  get tooltip() {
    if (this.showStatus) {
      return `${this.label}<small>${this.productionStatus}`
    }

    return this.label
  }

  get name() {
    if (this.vehicle && this.vehicle.name) {
      return this.vehicle.name
    }

    return null
  }

  get modelName() {
    if (this.paint && this.paint.rsiId) {
      return `${this.model.manufacturer.code} ${this.paint.name}`
    }

    return `${this.model.manufacturer.code} ${this.model.name}`
  }

  get length() {
    return this.model.fleetchartLength * this.sizeMultiplicator
  }

  get height() {
    return (this.length * this.sourceImageHeightMax) / this.sourceImageWidthMax
  }

  get imageWidth() {
    return Math.min(
      (this.height * this.sourceImageWidth) / this.sourceImageHeight,
      this.length
    )
  }

  get sourceImageHeightMax() {
    if (
      this.model.paint &&
      (this.model.paint.topView || this.model.paint.sideView)
    ) {
      const height = this.extractMaxHeightFromModel(this.model.paint)
      if (height) {
        return height
      }
    }

    return this.extractMaxHeightFromModel(this.model)
  }

  get sourceImageHeight() {
    if (this.paint && (this.paint.topView || this.paint.sideView)) {
      if (this.viewpointTop && this.paint.topView) {
        return this.paint.topViewHeight
      }

      if (this.viewpointSide && this.paint.sideView) {
        return this.paint.sideViewHeight
      }

      if (this.viewpointAngled && this.paint.angledView) {
        return this.paint.angledViewHeight
      }
    }

    if (this.viewpointTop && this.model.topView) {
      return this.model.topViewHeight
    }

    if (this.viewpointSide && this.model.sideView) {
      return this.model.sideViewHeight
    }

    if (this.viewpointAngled && this.model.angledView) {
      return this.model.angledViewHeight
    }

    return null
  }

  get sourceImageWidth() {
    if (this.paint && (this.paint.topView || this.paint.sideView)) {
      if (this.viewpointTop && this.paint.topView) {
        return this.paint.topViewWidth
      }

      if (this.viewpointSide && this.paint.sideView) {
        return this.paint.sideViewWidth
      }

      if (this.viewpointAngled && this.paint.angledView) {
        return this.paint.angledViewWidth
      }
    }

    if (this.viewpointTop && this.model.topView) {
      return this.model.topViewWidth
    }

    if (this.viewpointSide && this.model.sideView) {
      return this.model.sideViewWidth
    }

    if (this.viewpointAngled && this.model.angledView) {
      return this.model.angledViewWidth
    }

    return null
  }

  get sourceImageWidthMax() {
    if (
      this.model.paint &&
      (this.model.paint.topView || this.model.paint.sideView)
    ) {
      const width = this.extractMaxWidthFromModel(this.model.paint)
      if (width) {
        return width
      }
    }

    return this.extractMaxWidthFromModel(this.model)
  }

  extractMaxWidthFromModel(model) {
    return Math.max(
      model.topViewWidth,
      model.sideViewWidth,
      model.angledViewWidth
    )
  }

  extractMaxHeightFromModel(model) {
    return Math.max(
      model.topViewHeight,
      model.sideViewHeight,
      model.angledViewHeight
    )
  }

  topView(model) {
    const width = this.length * this.sizeMultiplicator * this.scale

    if (width > 2900) {
      return model.topView
    }

    if (width > 1900) {
      return model.topViewXlarge
    }

    if (width > 900) {
      return model.topViewLarge
    }

    if (width > 400) {
      return model.topViewMedium
    }

    return model.topViewSmall
  }

  sideView(model) {
    const width = this.length * this.sizeMultiplicator * this.scale

    if (width > 2900) {
      return model.sideView
    }

    if (width > 1900) {
      return model.sideViewXlarge
    }

    if (width > 900) {
      return model.sideViewLarge
    }

    if (width > 400) {
      return model.sideViewMedium
    }

    return model.sideViewSmall
  }

  angledView(model) {
    const width = this.length * this.sizeMultiplicator * this.scale

    if (width > 2900) {
      return model.angledView
    }

    if (width > 1900) {
      return model.angledViewXlarge
    }

    if (width > 900) {
      return model.angledViewLarge
    }

    if (width > 400) {
      return model.angledViewMedium
    }

    return model.angledViewSmall
  }
}
</script>
