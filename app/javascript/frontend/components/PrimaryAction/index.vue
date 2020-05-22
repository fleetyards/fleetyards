<template>
  <transition name="back-to-top-fade">
    <div
      v-tooltip="label"
      :aria-label="label"
      class="primary-action"
      @click="action"
    >
      <div class="primary-action-inner">
        <i :class="icon" />
      </div>
    </div>
  </transition>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component
export default class Panel extends Vue {
  @Prop({ default: 'fal fa-plus' }) icon!: string

  @Prop({ required: true }) action!: Function

  @Prop({ default: null }) label!: string
}
</script>
