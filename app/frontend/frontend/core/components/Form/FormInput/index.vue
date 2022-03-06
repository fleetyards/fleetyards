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
    <div
      class="form-input-wrapper"
      :class="{
        'from-input-wrapper-with-prefix': !!prefix,
        'from-input-wrapper-with-suffix': !!suffix,
      }"
    >
      <slot name="prefix">
        <div v-if="prefix" class="form-input-prefix">
          {{ prefix }}
        </div>
      </slot>
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
        :min="min"
        :max="max"
        :step="innerStep"
        :class="{
          clearable,
        }"
        @input="update"
        @blur="update"
      />
      <slot name="suffix">
        <div v-if="suffix" class="form-input-suffix">
          {{ suffix }}
        </div>
      </slot>
      <div v-if="inputValue && clearable" class="clear">
        <i
          class="fal fa-times"
          :class="{
            'with-label': !!innerLabel && !noLabel,
          }"
          @click="clear"
        />
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'FormInput',

  props: {
    autofocus: {
      default: false,
      type: Boolean,
    },

    clearable: {
      default: false,
      type: Boolean,
    },

    disabled: {
      default: false,
      type: Boolean,
    },

    error: {
      default: null,
      type: String,
    },
    hideLabelOnEmpty: {
      default: false,
      type: Boolean,
    },

    icon: {
      default: null,
      type: String,
    },

    id: {
      required: true,
      type: String,
    },

    inline: {
      default: false,
      type: Boolean,
    },

    label: {
      default: null,
      type: String,
    },

    max: {
      default: null,
      type: Number,
    },

    min: {
      default: null,
      type: Number,
    },

    noLabel: {
      default: false,
      type: Boolean,
    },

    noPlaceholder: {
      default: false,
      type: Boolean,
    },

    placeholder: {
      default: null,
      type: String,
    },

    prefix: {
      default: null,
      type: String,
    },

    size: {
      default: 'default',
      type: String,
      validator(value) {
        return ['default', 'large'].indexOf(value) !== -1
      },
    },

    step: {
      default: 0.01,
      type: Number,
    },

    suffix: {
      default: null,
      type: String,
    },

    translationKey: {
      default: null,
      type: String,
    },

    type: {
      default: 'text',
      type: String,
      validator(value) {
        return ['text', 'number', 'password', 'email', 'url', 'color'].includes(
          value
        )
      },
    },

    value: {
      default: null,
      type: [String, Number],
    },

    variant: {
      default: 'default',
      type: String,
      validator(value) {
        return ['default', 'clean'].indexOf(value) !== -1
      },
    },
  },
  data() {
    return {
      inputValue: null,
    }
  },

  computed: {
    cssClasses() {
      return {
        'form-input-clean': this.variant === 'clean',
        'form-input-clearable': this.clearable,
        'form-input-disabled': this.disabled,
        'form-input-inline': this.inline,
        'form-input-large': this.size === 'large',
        'has-error has-feedback': this.error,
        [`form-input-${this.type}`]: true,
      }
    },

    innerId() {
      return `${this.id}-${this._uid}`
    },

    innerLabel() {
      if (this.label) {
        return this.label
      }

      if (this.translationKey) {
        return this.$t(`labels.${this.translationKey}`)
      }

      return this.$t(`labels.${this.id}`)
    },

    innerPlaceholder() {
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
    },

    innerStep() {
      if (this.type === 'number') {
        return this.step
      }

      return null
    },
  },

  watch: {
    value() {
      this.inputValue = this.value
    },
  },

  mounted() {
    this.inputValue = this.value

    if (this.autofocus) {
      this.setFocus()
    }
  },

  methods: {
    clear() {
      this.inputValue = null
      this.update()
      this.$emit('clear')
    },

    setFocus() {
      if (this.$refs.input) {
        this.$refs.input.focus()
      }
    },

    update() {
      this.$emit('input', this.inputValue)
    },
  },
}
</script>
