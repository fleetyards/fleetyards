<template>
  <div
    ref="panelDetails"
    class="panel-details"
    :style="{ height: `${height}px` }"
  >
    <slot />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'

@Component
export default class PanelDetails extends Vue {
  height: number = 0

  @Prop({ default: false }) visible!: boolean

  @Watch('visible')
  onVisibleChange() {
    this.setupHeight()
  }

  mounted() {
    this.setupHeight()
  }

  setupHeight() {
    if (this.visible) {
      this.height = this.$refs.panelDetails.scrollHeight
    } else {
      this.height = 0
    }
  }
}
</script>
