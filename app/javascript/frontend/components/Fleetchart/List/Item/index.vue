<template>
  <div
    v-tooltip.bottom="label"
    class="fleetchart-item fade-list-item"
    :class="`fleetchart-item-${model.slug}`"
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
import FleetchartItemImage from './Image/index.vue'

@Component({
  components: {
    Btn,
    FleetchartItemImage,
  },
})
export default class FleetchartListItem extends Vue {
  @Prop() item!: Model | Vehicle

  @Prop() scale!: number

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
