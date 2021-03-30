<template>
  <div
    v-tooltip.bottom="tooltip"
    class="fleetchart-item fade-list-item"
    :class="cssClasses"
  >
    <FleetchartItemImage
      :label="label"
      :src="image"
      :length="model.length"
      :scale="scale"
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
  @Prop() item!: Model | Vehicle

  @Prop() scale!: number

  @Prop({ default: false }) showStatus!: boolean

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
    if (this.paint && this.paint.fleetchartImage) {
      return this.paint.fleetchartImage
    }

    return this.model.fleetchartImage
  }

  get productionStatus() {
    return this.$t(
      `labels.model.productionStatus.${this.model.productionStatus}`,
    )
  }

  get tooltip() {
    if (this.showStatus) {
      return `${this.label} (${this.productionStatus})`
    }

    return this.label
  }

  get label() {
    if (this.vehicle) {
      if (this.vehicle.name) {
        return this.vehicle.name
      }

      if (this.paint && this.paint.rsiId) {
        return this.modelLabel(this.paint.name)
      }
    }

    return this.modelLabel(this.model.name)
  }

  modelLabel(name) {
    return `${this.model.manufacturer.code} ${name}`
  }
}
</script>
