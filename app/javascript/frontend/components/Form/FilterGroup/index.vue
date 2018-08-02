<template>
  <div class="filter-list">
    <div
      :class="{
        active: visible,
        selected: selectedOptions.length > 0,
      }"
      class="filter-list-title"
      @click="toggle"
    >
      {{ label }}
      <i class="fa fa-chevron-right" />
    </div>
    <b-collapse
      :visible="selectedOptions.length > 0 && !visible"
      :id="selectedId"
      class="filter-list-items"
    >
      <a
        v-for="(option, index) in selectedOptions"
        :class="{
          active: selected(option.value),
        }"
        :key="`${selectedId}-${option.value}-${index}`"
        class="filter-list-item fade-list-item"
        @click="select(option.value)"
      >
        <span
          v-if="option.icon"
          class="filter-list-item-icon"
        >
          <img :src="option.icon" >
        </span>
        <span v-html="option.name"/>
        <span v-if="multiple">
          <i class="fal fa-plus" />
        </span>
      </a>
    </b-collapse>
    <b-collapse
      :visible="visible"
      :id="id"
      class="filter-list-items"
    >
      <a
        v-for="(option, index) in options"
        :class="{
          active: selected(option.value),
        }"
        :key="`${id}-${option.value}-${index}`"
        class="filter-list-item fade-list-item"
        @click="select(option.value)"
      >
        <span
          v-if="option.icon"
          class="filter-list-item-icon"
        >
          <img :src="option.icon" >
        </span>
        <span v-html="option.name"/>
        <span v-if="multiple">
          <i class="fal fa-plus" />
        </span>
      </a>
    </b-collapse>
  </div>
</template>

<script>
export default {
  props: {
    options: {
      type: Array,
      required: true,
    },
    value: {
      type: [Array, String],
      default() {
        if (this.multiple) {
          return []
        }
        return ''
      },
    },
    multiple: {
      type: Boolean,
      default: false,
    },
    label: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      visible: false,
      // eslint-disable-next-line no-underscore-dangle
      selectedId: this._uid.toString(),
      id: this._uid.toString(),
    }
  },
  computed: {
    selectedOptions() {
      if (this.multiple) {
        return this.options.filter(item => this.value.includes(item.value))
      }
      const selectedOption = this.options.find(item => item.value === this.value)
      return selectedOption ? [selectedOption] : []
    },
  },
  methods: {
    selected(option) {
      if (this.multiple) {
        return this.value.includes(option)
      }
      return this.value === option
    },
    select(option) {
      if (this.selected(option)) {
        if (this.multiple) {
          this.$emit('input', this.value.filter(item => item !== option))
        } else {
          this.$emit('input', '')
        }
      } else if (this.multiple) {
        const selected = JSON.parse(JSON.stringify(this.value))
        selected.push(option)
        this.$emit('input', selected)
      } else {
        this.$emit('input', option)
      }
    },
    unselect(option) {
      this.$emit('input', this.value.filter(item => item !== option))
    },
    toggle() {
      this.visible = !this.visible
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
