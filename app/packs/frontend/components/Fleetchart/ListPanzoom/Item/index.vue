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

  get modulePackage() {
    if (this.vehicle && this.vehicle.modulePackage) {
      return this.vehicle.modulePackage
    }

    return null
  }

  get image() {
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
  }

  get sourceImageHeight() {
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
  }

  get sourceImageWidth() {
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
  }

  get sourceImageWidthMax() {
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
  }

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
  }

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
  }

  topView(model) {
    const width = this.length * this.sizeMultiplicator * this.scale

    if (width > 1900) {
      return model.topView
    }

    if (width > 900) {
      return model.topViewLarge
    }

    return model.topViewMedium
  }

  sideView(model) {
    const width = this.length * this.sizeMultiplicator * this.scale

    if (width > 1900) {
      return model.sideView
    }

    if (width > 900) {
      return model.sideViewLarge
    }

    return model.sideViewMedium
  }

  angledView(model) {
    const width = this.length * this.sizeMultiplicator * this.scale

    if (width > 1900) {
      return model.angledView
    }

    if (width > 900) {
      return model.angledViewLarge
    }

    return model.angledViewMedium
  }
}
</script>
