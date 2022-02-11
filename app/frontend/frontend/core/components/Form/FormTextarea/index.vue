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
    id: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      default: null,
    },
    value: {
      type: [String, Number],
      default: null,
    },
    error: {
      type: String,
      default: null,
    },
    translationKey: {
      type: String,
      default: null,
    },
    autoFocus: {
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
    hideLabelOnEmpty: {
      type: Boolean,
      default: false,
    },
    placeholder: {
      type: String,
      default: null,
    },
    noPlaceholder: {
      type: Boolean,
      default: false,
    },
    clearable: {
      type: Boolean,
      default: false,
    },
    disabled: {
      type: Boolean,
      default: false,
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
      if (this.$refs.input) {
        this.$refs.input.focus()
      }
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
