<template>
  <div
    class="form-input"
    :class="cssClasses"
  >
    <label
      v-if="label"
      :for="id"
    >
      {{ label }}
    </label>
    <input
      :id="id"
      ref="input"
      v-model="inputValue"
      :placeholder="placeholder"
      :type="type"
      :aria-label="ariaLabel"
      :autofocus="autofocus"
      @input="update"
    >
    <Btn
      v-if="inputValue"
      variant="link"
      size="small"
      class="clear"
      :class="{
        'with-label': !!label
      }"
      @click.native="clear"
      v-html="'&times;'"
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
    value: {
      type: [String, Number],
      default: null,
    },
    type: {
      type: String,
      default: 'text',
      validator(value) {
        return ['text', 'number'].indexOf(value) !== -1
      },
    },
    id: {
      type: String,
      default: null,
    },
    label: {
      type: String,
      default: null,
    },
    placeholder: {
      type: String,
      default: null,
    },
    ariaLabel: {
      type: String,
      default: null,
    },
    autofocus: {
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
    cssClasses() {
      return {
        'form-input-large': this.size === 'large',
        'form-input-clean': this.variant === 'clean',
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
