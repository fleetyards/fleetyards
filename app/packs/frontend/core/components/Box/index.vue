<template>
  <div
    :class="{
      'box-large': large,
    }"
    class="box"
  >
    <Panel>
      <div class="box-inner">
        <slot />
      </div>
    </Panel>
    <slot name="footer" />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Panel from 'frontend/core/components/Panel/index.vue'

@Component({ components: { Panel } })
export default class Box extends Vue {
  @Prop({ default: false }) large!: boolean
}
</script>
