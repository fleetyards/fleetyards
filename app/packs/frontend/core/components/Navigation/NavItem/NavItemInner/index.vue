<template>
  <div
    class="nav-item-inner"
    :class="{
      'nav-item-inner-slim': slim,
    }"
  >
    <img
      v-if="image"
      :src="image"
      :alt="`${label} image`"
      class="nav-item-image"
    />
    <i
      v-else-if="icon"
      :class="{
        [icon]: true,
      }"
    />
    <span v-else class="nav-item-image-empty">
      {{ firstLetter }}
    </span>
    <transition name="fade-nav">
      <span
        v-if="!slim"
        :class="{
          'nav-item-text': !icon && !image,
        }"
      >
        {{ label }}
      </span>
    </transition>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component<NavItemInner>({})
export default class NavItemInner extends Vue {
  get firstLetter() {
    return this.label.charAt(0)
  }

  @Prop({ default: '' }) label: string

  @Prop({ default: null }) icon: string | null

  @Prop({ default: null }) image: string | null

  @Prop({ default: false }) slim: boolean
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
