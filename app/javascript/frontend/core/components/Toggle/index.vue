<template>
  <button
    type="button"
    :class="cssClasses"
    :disabled="disabled || loading"
    @click="toggle"
  >
    <BtnInner :loading="loading">
      <slot name="left" />
    </BtnInner>
    <BtnInner :loading="loading">
      <slot name="right" />
    </BtnInner>
  </button>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import BtnInner from 'frontend/core/components/Btn/Inner'

@Component<Toggle>({
  components: {
    BtnInner,
  },
})
export default class Toggle extends Vue {
  @Prop({ default: false }) loading: boolean

  @Prop({ default: true }) activeLeft: boolean

  @Prop({ default: false }) activeRight: boolean

  @Prop({
    default: 'default',
    validator(value) {
      return ['default', 'danger'].includes(value)
    },
  })
  variant: string

  @Prop({
    default: 'default',
    validator(value) {
      return ['default', 'small', 'large'].includes(value)
    },
  })
  size: string

  @Prop({ default: false }) inline: boolean

  @Prop({ default: false }) disabled: boolean

  get cssClasses() {
    return {
      'panel-btn': true,
      'panel-btn-toggle': true,
      'panel-btn-danger': this.variant === 'danger',
      'panel-btn-small': this.size === 'small',
      'panel-btn-large': this.size === 'large',
      'panel-btn-inline': this.inline,
      'active-left': this.activeLeft,
      'active-right': this.activeRight,
    }
  }

  toggle() {
    if (this.activeRight) {
      this.$emit('toggle:left')
    } else {
      this.$emit('toggle:right')
    }
  }
}
</script>
