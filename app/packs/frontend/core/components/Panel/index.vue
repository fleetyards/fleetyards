<template>
  <div
    :class="{
      'panel-outer-spacing': outerSpacing,
      'panel-highlight': highlight,
    }"
    class="panel-wrapper"
  >
    <div
      :class="{
        [variantClass]: true,
        [transparencyClass]: true,
      }"
      class="panel"
    >
      <div
        :class="{
          'panel-inner-text': forText,
        }"
        class="panel-inner"
      >
        <slot />
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component
export default class Panel extends Vue {
  private get variantClass() {
    return `panel-${this.variant}`
  }

  private get transparencyClass() {
    return `panel-transparency-${this.transparency}`
  }

  @Prop({ default: true }) outerSpacing!: boolean

  @Prop({ default: 'default' }) transparency!: 'default' | 'more' | 'complete'

  @Prop({ default: false }) highlight!: boolean

  @Prop({ default: false }) forText!: boolean

  @Prop({ default: 'default' }) variant!: 'default' | 'primary' | 'success'
}
</script>
