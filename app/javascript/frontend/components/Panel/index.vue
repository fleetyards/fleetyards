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
import Component from 'vue-class-component'
import { Prop } from 'vue-property-decorator'
import Vue from 'vue'

@Component
export default class Panel extends Vue {
  @Prop({ default: true })
  private outerSpacing!: boolean

  @Prop({ default: 'default' })
  private transparency!: 'default' | 'more' | 'complete'

  @Prop({ default: false })
  private highlight!: boolean

  @Prop({ default: false })
  private forText!: boolean

  @Prop({ default: 'default' })
  private variant!: 'default' | 'primary' | 'success'

  private get variantClass() {
    return `panel-${this.variant}`
  }

  private get transparencyClass() {
    return `panel-transparency-${this.transparency}`
  }
}
</script>
