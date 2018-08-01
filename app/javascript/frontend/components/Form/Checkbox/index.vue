<template>
  <div class="form-group">
    <input
      :checked="value ? 'checked' : null"
      :disabled="disabled ? 'disabled' : null"
      :id="checkboxID"
      class="checkbox"
      type="checkbox"
      @change="change"
    >
    <label :for="checkboxID">{{ label }}</label>
  </div>
</template>

<script>
export default {
  props: {
    id: {
      type: String,
      default: '',
    },
    label: {
      type: String,
      required: true,
    },
    value: {
      type: Boolean,
      required: true,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    checkboxID() {
      // eslint-disable-next-line no-underscore-dangle
      return `${this.id}-${this._uid.toString()}`
    },
  },
  methods: {
    change(event) {
      this.$emit('input', event.target.checked)
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
