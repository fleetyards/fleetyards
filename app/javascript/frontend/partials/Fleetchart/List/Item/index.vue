<template>
  <div v-tooltip.bottom="label" class="fleetchart-item fade-list-item">
    <FleetchartItemImage
      :label="model.name"
      :src="fleetchartImage"
      :length="model.length"
      :scale="scale"
    />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/components/Btn/index.vue'
import FleetchartItemImage from './Image/index.vue'

@Component({
  components: {
    Btn,
    FleetchartItemImage,
  },
})
export default class FleetchartListItem extends Vue {
  @Prop() model!: Model

  @Prop() fleetchartImage!: string

  @Prop() scale!: number

  get label() {
    return `${this.model.manufacturer.code} ${this.model.name}`
  }
}
</script>
