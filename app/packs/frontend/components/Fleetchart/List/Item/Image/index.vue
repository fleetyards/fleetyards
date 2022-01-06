<template>
  <img
    v-if="src"
    :src="src"
    :style="{
      'width': `${width}px`,
      'max-height': height ? `${height}px` : null,
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
import { Component, Prop } from 'vue-property-decorator'
import Vue from 'vue'

@Component({})
export default class FleetchartListItemImage extends Vue {
  @Prop({ required: true }) src!: string

  @Prop({ required: true }) label!: string

  @Prop({ required: true }) width!: number

  @Prop({ default: null }) height!: number | null
}
</script>
