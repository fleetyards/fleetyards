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
    <div class="form-input-wrapper">
      <textarea
        :id="innerId"
        v-model="inputValue"
        v-tooltip.right="error"
        :placeholder="innerPlaceholder"
        :data-test="`input-${id}`"
        :aria-label="innerLabel"
        :autofocus="autofocus"
        :disabled="disabled ? 'disabled' : null"
        :name="id"
        :rows="inputValue ? 10 : 5"
        @input="update"
        @blur="update"
      />
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import VueTrix from 'vue-trix'

@Component<FormTextarea>({
  components: {
    VueTrix,
  },
})
export default class FormTextarea extends Vue {
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
      'form-input-clearable': this.clearable,
    }
  }

  @Prop({ required: true }) id!: string

  @Prop({ default: null }) icon!: string

  @Prop({ default: null }) value!: string | number

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

  inputValue: any = null

  @Watch('value')
  onValueChange() {
    this.inputValue = this.value
  }

  mounted() {
    this.inputValue = this.value
  }

  setFocus() {
    if (this.$refs.input) {
      this.$refs.input.focus()
    }
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
