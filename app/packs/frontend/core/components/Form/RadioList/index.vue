<template>
  <div class="form-group">
    <label :for="radioID">
      {{ label }}
    </label>
    <div class="radio-list">
      <div v-if="resetLabel" :class="{ 'radio-inline': inline }" class="radio">
        <input
          :id="`${radioID}-reset`"
          :checked="!value"
          :disabled="disabled ? 'disabled' : null"
          :name="name"
          type="radio"
          @change="clear"
        />
        <label :for="`${radioID}-reset`" class="radio-label">
          {{ resetLabel }}
        </label>
      </div>
      <div
        v-for="(option, index) in options"
        :key="`${radioID}-${option.value}-${index}`"
        :class="{ 'radio-inline': inline }"
        class="radio"
      >
        <input
          :id="`${radioID}-${option.value}`"
          :checked="value === option.value"
          :disabled="disabled ? 'disabled' : null"
          :name="name"
          :value="option.value"
          type="radio"
          @change="change"
        />
        <label :for="`${radioID}-${option.value}`" class="radio-label">
          {{ option.name }}
        </label>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'RadioList',

  props: {
    name: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    options: {
      type: Array,
      required: true,
    },
    resetLabel: {
      type: String,
      default: '',
    },
    value: {
      type: String,
      default: '',
    },
    inline: {
      type: Boolean,
      default: true,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    radioID() {
      // eslint-disable-next-line no-underscore-dangle
      return `${this.name}-${this._uid.toString()}`
    },
  },
  methods: {
    change(event) {
      this.$emit('input', event.target.value)
    },
    clear() {
      this.$emit('input', null)
    },
  },
}
</script>
