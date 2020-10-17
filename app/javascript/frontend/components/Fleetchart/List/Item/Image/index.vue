<template>
  <img
    v-if="src"
    :src="src"
    :style="{
      height: `${length * lengthMultiplicator}px`,
    }"
    :alt="label"
    class="fleetchart-item-image"
    :crossorigin="true"
  />
  <span v-else>
    <i class="fal fa-question-circle" />
    <p>{{ label }}</p>
  </span>
</template>

<script lang="ts">
import { Component, Prop } from 'vue-property-decorator'
import Vue from 'vue'

@Component({})
export default class FleetchartListItemImage extends Vue {
  @Prop() src!: string

  @Prop() label!: string

  @Prop() length!: number

  @Prop() scale!: number

  get lengthMultiplicator() {
    return (this.scale / 100) * 4
  }
}
</script>
