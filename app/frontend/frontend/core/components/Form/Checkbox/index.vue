<template>
  <div
    class="form-group form-group-checkbox"
    :class="{
      'form-group-checkbox-expanded': !slim,
    }"
  >
    <input
      :id="checkboxID"
      v-model="internalValue"
      :checked="value ? 'checked' : null"
      :disabled="disabled ? 'disabled' : null"
      class="checkbox"
      type="checkbox"
      :value="checkboxValue"
      :data-test="`checkbox-${id}`"
      @change="update"
    />
    <label :for="checkboxID">
      {{ label }}
    </label>
  </div>
</template>

<script>
export default {
  name: 'FormCheckbox',

  props: {
    checkboxValue: {
      default: null,
      type: [String, Number],
    },

    disabled: {
      default: false,
      type: Boolean,
    },

    id: {
      default: '',
      type: String,
    },

    label: {
      default: null,
      type: String,
    },

    slim: {
      default: true,
      type: Boolean,
    },

    value: {
      default: null,
      type: [Boolean, Array],
    },
  },
  data() {
    return {
      internalValue: null,
    }
  },

  computed: {
    checkboxID() {
      // eslint-disable-next-line no-underscore-dangle
      return `${this.id}-${this._uid.toString()}`
    },
  },

  watch: {
    value() {
      this.internalValue = this.value
    },
  },

  mounted() {
    this.internalValue = this.value
  },

  methods: {
    update() {
      this.$emit('input', this.internalValue)
    },
  },
}
</script>
