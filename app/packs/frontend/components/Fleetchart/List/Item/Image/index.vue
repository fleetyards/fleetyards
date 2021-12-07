<template>
  <img
    v-if="src"
    :src="src"
    :style="{
      width: `${length * multiplicator}px`,
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
  @Prop() src!: string

  @Prop() label!: string

  @Prop() length!: number

  get multiplicator() {
    return 4
  }
}
</script>
