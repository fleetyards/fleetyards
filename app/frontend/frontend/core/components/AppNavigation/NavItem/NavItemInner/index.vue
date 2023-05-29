<template>
  <div
    class="nav-item-inner"
    :class="{
      'nav-item-inner-slim': slim,
    }"
  >
    <span class="nav-item-icon">
      <img
        v-if="image"
        :src="image"
        :alt="`${label} image`"
        class="nav-item-image"
        :class="{ 'nav-item-image-avatar': avatar }"
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
    </span>
    <span
      v-if="!slim"
      :class="{
        'nav-item-text': !icon && !image,
      }"
    >
      {{ label }}
    </span>
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";

@Component<NavItemInner>({})
export default class NavItemInner extends Vue {
  @Prop({ default: "" }) label: string;

  @Prop({ default: null }) icon: string | null;

  @Prop({ default: null }) image: string | null;

  @Prop({ default: false }) avatar: boolean;

  @Prop({ default: false }) slim: boolean;

  get firstLetter() {
    return this.label.charAt(0);
  }
}
</script>

<style lang="scss" scoped>
@import "index";
</style>
