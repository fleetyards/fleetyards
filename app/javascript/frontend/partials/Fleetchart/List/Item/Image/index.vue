<template>
  <img
    v-if="model.fleetchartImage"
    :src="model.fleetchartImage"
    :style="{
      height: `${model.length * lengthMultiplicator}px`,
    }"
    :alt="model.name"
    class="fleetchart-item-image"
  />
  <span v-else>
    <i class="fal fa-question-circle" />
    <p>{{ model.name }}</p>
  </span>
</template>

<script lang="ts">
import { Component, Prop } from 'vue-property-decorator'
import Vue from 'vue'

@Component({})
export default class FleetchartListItemImage extends Vue {
  @Prop() model!: Model

  @Prop() scale!: number

  get lengthMultiplicator() {
    return (this.scale / 100) * 4
  }
}
</script>
