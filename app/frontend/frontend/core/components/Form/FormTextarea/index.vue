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

<script>
export default {
  name: 'FormTextarea',

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

    label: {
      default: null,
      type: String,
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

    translationKey: {
      default: null,
      type: String,
    },

    value: {
      default: null,
      type: [String, Number],
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
        'form-input-clearable': this.clearable,
        'has-error has-feedback': this.error,
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
    clear() {
      this.$emit('input', null)
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
