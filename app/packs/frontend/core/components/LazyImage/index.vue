<template>
  <component
    :is="componentType"
    v-if="src"
    :key="`${src}-${uuid}`"
    v-lazy:background-image="src"
    v-bind="componentArgs"
    class="lazy-image"
  >
    <slot />
  </component>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component<LazyImage>({})
export default class LazyImage extends Vue {
  @Prop({ required: true }) src!: string

  @Prop({ default: 'image' }) alt!: string

  @Prop({ default: null }) href!: string

  @Prop({ to: null }) to!: Object

  get uuid() {
    return this._uid
  }

  get componentType() {
    if (this.to) {
      return 'router-link'
    }
    if (this.href) {
      return 'a'
    }
    return 'div'
  }

  get componentArgs() {
    if (this.to) {
      return {
        to: this.to,
      }
    }

    if (this.href) {
      return {
        href: this.href,
      }
    }

    return {}
  }
}
</script>
