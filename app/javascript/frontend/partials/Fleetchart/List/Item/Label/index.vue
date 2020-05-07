<template>
  <div class="fleetchart-item-label">
    {{ label }}
  </div>
</template>

<script lang="ts">
import { Component, Prop } from 'vue-property-decorator'
import Vue from 'vue'

@Component({})
export default class FleetchartListItemLabel extends Vue {
  @Prop() label!: string
}
</script>
