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
      <template v-if="multiple || !selectedOptions.length">
        {{ label }}
      </template>
      <template v-else>
        {{ selectedOptions[0][labelAttr] }}
      </template>
      <SmallLoader :loading="loading" />
      <i class="fa fa-chevron-right" />
    </div>
    <b-collapse
      v-if="multiple"
      :id="`${groupID}-${selectedId}`"
      :visible="selectedOptions.length > 0 && !visible"
      class="filter-list-items"
    >
      <a
        v-for="(option, index) in selectedOptions"
        :key="`${groupID}-${selectedId}-${option[valueAttr]}-${index}`"
        :class="{
          active: selected(option[valueAttr]),
        }"
        class="filter-list-item fade-list-item"
        @click="select(option[valueAttr])"
      >
        <span
          v-if="option[iconAttr]"
          class="filter-list-item-icon"
        >
          <img :src="option[iconAttr]">
        </span>
        <span v-html="option[labelAttr]" />
        <span v-if="multiple">
          <i class="fal fa-plus" />
        </span>
      </a>
    </b-collapse>
    <div
      v-if="searchable && visible"
      class="filter-list-search"
    >
      <input
        ref="searchInput"
        v-model="search"
        :placeholder="searchLabel || t('actions.find')"
        class="form-control"
        @input="onSearch"
      >
      <a
        v-if="search"
        class="btn btn-clear"
        @click="clearSearch"
        v-html="'&times;'"
      />
    </div>
    <b-collapse
      :id="`${groupID}-${id}`"
      :visible="visible"
      class="filter-list-items"
    >
      <a
        v-for="(option, index) in filteredOptions"
        :key="`${groupID}-${id}-${option[valueAttr]}-${index}`"
        :class="{
          active: selected(option[valueAttr]),
        }"
        class="filter-list-item fade-list-item"
        @click="select(option[valueAttr])"
      >
        <span
          v-if="option[iconAttr]"
          class="filter-list-item-icon"
        >
          <img :src="option[iconAttr]">
        </span>
        <span v-html="option[labelAttr]" />
        <span v-if="multiple">
          <i class="fal fa-plus" />
        </span>
      </a>
      <InfiniteLoading
        v-if="fetch && fetchedOptions.length && !search && paginated"
        ref="infiniteLoading"
        :distance="100"
        @infinite="fetchMore"
      >
        <span slot="no-more" />
        <span slot="spinner" />
      </InfiniteLoading>
    </b-collapse>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import SmallLoader from 'frontend/components/SmallLoader'
import debounce from 'lodash.debounce'
import InfiniteLoading from 'vue-infinite-loading'

export default {
  components: {
    SmallLoader,
    InfiniteLoading,
  },
  mixins: [I18n],
  props: {
    name: {
      type: String,
      required: true,
    },
    options: {
      type: Array,
      default() {
        return []
      },
    },
    value: {
      type: [Array, String],
      default() {
        if (this.multiple) {
          return []
        }
        return null
      },
    },
    valueAttr: {
      type: String,
      default: 'value',
    },
    labelAttr: {
      type: String,
      default: 'name',
    },
    iconAttr: {
      type: String,
      default: 'icon',
    },
    multiple: {
      type: Boolean,
      default: false,
    },
    searchable: {
      type: Boolean,
      default: false,
    },
    paginated: {
      type: Boolean,
      default: false,
    },
    label: {
      type: String,
      default: '',
    },
    fetch: {
      type: Function,
      default: null,
    },
    searchLabel: {
      type: String,
      default: null,
    },
  },
  data() {
    return {
      visible: false,
      search: null,
      page: 1,
      loading: false,
      fetchedOptions: [],
      selectedId: this._uid.toString(),
      id: this._uid.toString(),
    }
  },
  computed: {
    groupID() {
      return `${this.name}-${this._uid.toString()}`
    },
    availableOptions() {
      if (this.fetch) {
        if (this.paginated) {
          return this.sort(this.fetchedOptions)
        }
        return this.fetchedOptions
      }
      if (this.paginated) {
        return this.sort(this.options)
      }
      return this.options
    },
    selectedOptions() {
      if (this.multiple) {
        return this.availableOptions.filter(item => this.value.includes(item[this.valueAttr]))
      }
      const selectedOption = this.availableOptions.find(item => item[this.valueAttr] === this.value)
      return selectedOption ? [selectedOption] : []
    },
    filteredOptions() {
      if (this.search) {
        return this.availableOptions.filter(
          item => item[this.labelAttr].toLowerCase().includes(this.search.toLowerCase()),
        )
      }
      return this.availableOptions
    },
  },
  mounted() {
    if (this.fetch) {
      this.fetchOptions()
    }
  },
  methods: {
    onSearch: debounce(function debounced() {
      if (this.paginated && this.search) {
        this.page = 1
        this.fetchOptions()
      }
    }, 300),
    async fetchOptions() {
      if (!this.fetch) {
        return
      }
      this.loading = true
      const response = await this.fetch({ page: this.page, search: this.search })
      this.loading = false
      if (this.$refs.infiniteLoading) {
        this.$refs.infiniteLoading.$emit('$InfiniteLoading:reset')
      }
      if (!response.error) {
        this.addOptions(response.data)
        this.fetchMissingOption()
      }
    },
    async fetchMissingOption() {
      if ((this.multiple && this.selectedOptions.length === this.value.length)
        || (!this.multiple && this.selectedOptions[0] === this.value)) {
        return
      }

      this.loading = true
      const response = await this.fetch({ page: this.page, missingValue: this.value })
      this.loading = false
      if (!response.error) {
        this.addOptions(response.data)
      }
    },
    async fetchMore($state) {
      this.loading = true
      this.page += 1
      const response = await this.fetch({ page: this.page })
      $state.loaded()
      this.loading = false
      if (!response.error) {
        if (response.data.length === 0) {
          $state.complete()
        }
        this.addOptions(response.data)
      }
    },
    sort(options) {
      const sortedOptions = JSON.parse(JSON.stringify(options))
      return sortedOptions.sort((a, b) => {
        if (a[this.labelAttr] < b[this.labelAttr]) {
          return -1
        }
        if (a[this.labelAttr] > b[this.labelAttr]) {
          return 1
        }
        return 0
      })
    },
    addOptions(newOptions) {
      newOptions.forEach((item) => {
        if (!this.availableOptions.find(
          option => option[this.valueAttr] === item[this.valueAttr],
        )) {
          this.fetchedOptions.push(item)
        }
      })
    },
    clearSearch() {
      this.search = null
    },
    selected(option) {
      if (this.multiple) {
        return this.value.includes(option)
      }
      return this.value === option
    },
    select(option) {
      this.clearSearch()
      if (this.selected(option)) {
        if (this.multiple) {
          this.$emit('input', this.value.filter(item => item !== option))
        } else {
          this.$emit('input', null)
        }
      } else if (this.multiple) {
        const selected = JSON.parse(JSON.stringify(this.value))
        selected.push(option)
        this.$emit('input', selected)
        this.focusSearch()
      } else {
        this.$emit('input', option)
        this.toggle()
      }
    },
    unselect(option) {
      this.$emit('input', this.value.filter(item => item !== option))
    },
    toggle() {
      this.visible = !this.visible
      this.focusSearch()
    },
    focusSearch() {
      if (this.searchable && this.visible) {
        this.$nextTick(() => this.$refs.searchInput.focus())
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
