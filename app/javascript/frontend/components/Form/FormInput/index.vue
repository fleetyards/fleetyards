<template>
  <div :key="innerId" class="form-input" :class="cssClasses">
    <transition name="fade">
      <label
        v-show="!hideLabelOnEmpty || inputValue"
        v-if="innerLabel && !noLabel"
        :for="id"
      >
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

<script>
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Btn,
  },

  props: {
    id: {
      type: String,
      required: true,
    },

    value: {
      type: [String, Number],
      default: null,
    },

    type: {
      type: String,
      default: 'text',
      validator(value) {
        return (
          ['text', 'number', 'password', 'email', 'url'].indexOf(value) !== -1
        )
      },
    },

    error: {
      type: String,
      default: null,
    },

    translationKey: {
      type: String,
      default: null,
    },

    autofocus: {
      type: Boolean,
      default: false,
    },

    hideLabelOnEmpty: {
      type: Boolean,
      default: false,
    },

    label: {
      type: String,
      default: null,
    },

    noLabel: {
      type: Boolean,
      default: false,
    },

    noPlaceholder: {
      type: Boolean,
      default: false,
    },

    placeholder: {
      type: String,
      default: null,
    },

    clearable: {
      type: Boolean,
      default: false,
    },

    variant: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'clean'].indexOf(value) !== -1
      },
    },

    size: {
      type: String,
      default: 'default',
      validator(value) {
        return ['default', 'large'].indexOf(value) !== -1
      },
    },
  },

  data() {
    return {
      inputValue: null,
    }
  },

  computed: {
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

    cssClasses() {
      return {
        'has-error has-feedback': this.error,
        'form-input-large': this.size === 'large',
        'form-input-clean': this.variant === 'clean',
        'form-input-clearable': this.clearable,
      }
    },
  },

  watch: {
    value() {
      this.inputValue = this.value
    },
  },

  mounted() {
    this.inputValue = this.value
  },

  methods: {
    setFocus() {
      this.$refs.input.focus()
    },

    update() {
      this.$emit('input', this.inputValue)
    },

    clear() {
      this.$emit('input', null)
      this.$emit('clear')
    },
  },
}
</script>
