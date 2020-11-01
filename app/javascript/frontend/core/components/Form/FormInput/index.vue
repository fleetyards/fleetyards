<template>
  <div :key="innerId" class="form-input" :class="cssClasses">
    <transition name="fade">
      <label
        v-show="!hideLabelOnEmpty || inputValue"
        v-if="innerLabel && !noLabel"
        :for="id"
      >
        <i v-if="icon" :class="icon" />
        {{ innerLabel }}
      </label>
    </transition>
    <input
      :id="innerId"
      ref="input"
      v-model="inputValue"
      v-tooltip.right="error"
      :placeholder="innerPlaceholder"
      :type="type"
      :data-test="`input-${id}`"
      :aria-label="innerLabel"
      :autofocus="autofocus"
      :disabled="disabled ? 'disabled' : null"
      :name="id"
      @input="update"
      @blur="update"
    />
    <i
      v-if="inputValue && clearable"
      class="fal fa-times clear"
      :class="{
        'with-label': !!innerLabel && !noLabel,
      }"
      @click="clear"
    />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'

@Component<FormInput>({})
export default class FormInput extends Vue {
  @Prop({ required: true }) id!: string

  @Prop({ default: null }) icon!: string

  @Prop({ default: null }) value!: string | number

  @Prop({
    default: 'text',
    validator(value) {
      return ['text', 'number', 'password', 'email', 'url', 'color'].includes(
        value,
      )
    },
  })
  type!: string

  @Prop({ default: null }) error!: string

  @Prop({ default: null }) translationKey!: string

  @Prop({ default: false }) autofocus!: boolean

  @Prop({ default: false }) hideLabelOnEmpty!: boolean

  @Prop({ default: null }) label!: string

  @Prop({ default: false }) noLabel!: boolean

  @Prop({ default: false }) noPlaceholder!: boolean

  @Prop({ default: null }) placeholder!: string

  @Prop({ default: false }) clearable!: boolean

  @Prop({ default: false }) disabled!: boolean

  @Prop({
    default: 'default',
    validator(value) {
      return ['default', 'clean'].indexOf(value) !== -1
    },
  })
  variant!: string

  @Prop({
    default: 'default',
    validator(value) {
      return ['default', 'large'].indexOf(value) !== -1
    },
  })
  size!: string

  inputValue: any = null

  get innerId() {
    return `${this.id}-${this._uid}`
  }

  get innerLabel() {
    if (this.label) {
      return this.label
    }

    if (this.translationKey) {
      return this.$t(`labels.${this.translationKey}`)
    }

    return this.$t(`labels.${this.id}`)
  }

  get innerPlaceholder() {
    if (this.noPlaceholder) {
      return null
    }

    if (this.placeholder) {
      return this.placeholder
    }

    if (this.translationKey) {
      return this.$t(`placeholders.${this.translationKey}`)
    }

    return this.$t(`placeholders.${this.id}`)
  }

  get cssClasses() {
    return {
      'has-error has-feedback': this.error,
      'form-input-large': this.size === 'large',
      'form-input-clean': this.variant === 'clean',
      'form-input-clearable': this.clearable,
    }
  }

  @Watch('value')
  onValueChange() {
    this.inputValue = this.value
  }

  mounted() {
    this.inputValue = this.value
  }

  setFocus() {
    this.$refs.input.focus()
  }

  update() {
    this.$emit('input', this.inputValue)
  }

  clear() {
    this.$emit('input', null)
    this.$emit('clear')
  }
}
</script>
