<template>
  <img
    v-if="src"
    :src="src"
    :style="{
      height: `${length * lengthMultiplicator}px`,
    }"
    :alt="label"
    class="fleetchart-item-image"
  />
  <span v-else>
    <i class="fal fa-question-circle" />
    <p>{{ label }}</p>
  </span>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component({})
export default class FleetchartListItemImage extends Vue {
  get lengthMultiplicator() {
    return (this.scale / 100) * 4
  }

  @Prop() src!: string

  @Prop() label!: string

  @Prop() length!: number

  @Prop() scale!: number
}
</script>
