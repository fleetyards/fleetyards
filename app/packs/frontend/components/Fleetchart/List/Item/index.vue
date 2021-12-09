<template>
  <div class="fleetchart-item fade-list-item" :class="cssClasses">
    <div v-if="showLabel" class="fleetchart-item-label">
      <template v-if="name">
        {{ name }}
        <small>
          {{ modelName }}
          <template v-if="showStatus">
            <br />
            {{ productionStatus }}
          </template>
        </small>
      </template>
      <template v-else>
        {{ modelName }}
        <small v-if="showStatus">
          {{ productionStatus }}
        </small>
      </template>
    </div>

    <FleetchartItemImage
      :label="name || modelName"
      :src="image"
      :length="length"
      :width="model.width"
    />
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

  get cssClasses() {
    const cssClasses = [`fleetchart-item-${this.model.slug}`]

    if (this.showStatus) {
      cssClasses.push(`status-${this.model.productionStatus}`)
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

  topView(model) {
    return model.topViewResized
  }

  sideView(model) {
    return model.sideViewResized
  }

  angledView(model) {
    return model.angledViewResized
  }
}
</script>
