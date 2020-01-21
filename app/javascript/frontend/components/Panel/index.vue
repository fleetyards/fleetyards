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
import { Component, Prop } from 'vue-property-decorator'
import Vue from 'vue'

@Component
export default class Panel extends Vue {
  @Prop({ default: true })
  public outerSpacing!: boolean

  @Prop({
    default: 'default',
    validator(value) {
      return ['default', 'more', 'complete'].indexOf(value) !== -1
    },
  })
  public transparency!: string

  @Prop({ default: false })
  public highlight!: boolean

  @Prop({ default: false })
  public forText!: boolean

  @Prop({
    default: 'default',
    validator(value) {
      return ['default', 'primary', 'success'].indexOf(value) !== -1
    },
  })
  public variant!: string

  public get variantClass() {
    return `panel-${this.variant}`
  }

  public get transparencyClass() {
    return `panel-transparency-${this.transparency}`
  }
}
</script>
