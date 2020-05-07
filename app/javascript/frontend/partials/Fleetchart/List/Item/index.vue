<template>
  <div v-tooltip.bottom="label" class="fleetchart-item fade-list-item">
    <FleetchartItemImage :model="model" :scale="scale" />
    <FleetchartItemLabel :label="label" />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/components/Btn/index.vue'
import FleetchartItemImage from './Image/index.vue'
import FleetchartItemLabel from './Label/index.vue'

@Component({
  components: {
    Btn,
    FleetchartItemImage,
    FleetchartItemLabel,
  },
})
export default class FleetchartListItem extends Vue {
  @Prop() model!: Model

  @Prop() scale!: number

  get label() {
    return `${this.model.manufacturer.code} ${this.model.name}`
  }
}
</script>
