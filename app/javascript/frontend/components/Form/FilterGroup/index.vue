<template>
  <div
    ref="filterGroup"
    class="filter-list"
  >
    <div
      :class="{
        active: visible,
        disabled: disabled,
        selected: selectedOptions.length > 0,
      }"
      class="filter-list-title"
      @click="toggle"
    >
      {{ label }}
      <SmallLoader :loading="loading" />
      <i class="fa fa-chevron-right" />
    </div>
    <b-collapse
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
    <b-collapse
      :id="`${groupID}-${id}`"
      :visible="visible"
      class="filter-list-items-wrapper"
    >
      <FormInput
        v-if="searchable"
        ref="searchInput"
        v-model="search"
        :placeholder="searchLabel || $t('actions.find')"
        class="filter-list-search"
        variant="clean"
        @input="onSearch"
      />
      <div class="filter-list-items">
        <a
          v-for="(option, index) in filteredOptions"
          :key="`${groupID}-${id}-${option[valueAttr]}-${index}`"
          :class="{
            active: selected(option[valueAttr]),
          }"
          class="filter-list-item fade-list-item"
          @click="select(returnObject ? option : option[valueAttr])"
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
          v-if="shouldFetch && fetchedOptions.length && !search && paginated"
          ref="infiniteLoading"
          :distance="100"
          @infinite="fetchMore"
        >
          <span slot="no-more" />
          <span slot="spinner" />
        </InfiniteLoading>
      </div>
    </b-collapse>
  </div>
</template>

<script>
import SmallLoader from 'frontend/components/SmallLoader'
import FormInput from 'frontend/components/Form/FormInput'
import debounce from 'lodash.debounce'
import InfiniteLoading from 'vue-infinite-loading'

export default {
  components: {
    SmallLoader,
    InfiniteLoading,
    FormInput,
  },

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

    disabled: {
      type: Boolean,
      default: false,
    },

    searchable: {
      type: Boolean,
      default: false,
    },

    returnObject: {
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

    fetchPath: {
      type: String,
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
    shouldFetch() {
      return this.fetch || this.fetchPath
    },

    groupID() {
      return `${this.name}-${this._uid.toString()}`
    },

    availableOptions() {
      if (this.shouldFetch) {
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
    if (this.shouldFetch) {
      this.fetchOptions()
    }
  },

  created() {
    document.addEventListener('click', this.documentClick)
  },

  destroyed () {
    document.removeEventListener('click', this.documentClick)
  },

  methods: {
    documentClick(event) {
      const element = this.$refs.filterGroup
      const { target } = event

      if (element !== target && !element.contains(target)) {
        this.visible = false
      }
    },

    onSearch: debounce(function debounced() {
      if (this.paginated && this.search) {
        this.page = 1
        this.fetchOptions()
      }
    }, 300),

    internalFetch(args) {
      if (this.fetch) {
        return this.fetch(args)
      }

      const query = {
        q: {},
      }
      if (args.search && this.searchable) {
        query.q.nameCont = args.search
      } else if (args.missingValue && this.paginated) {
        query.q.nameIn = args.missingValue
      } else if (args.page && this.paginated) {
        query.page = args.page
      }
      return this.$api.get(this.fetchPath, query)
    },

    async fetchOptions() {
      if (!this.shouldFetch) {
        return
      }

      this.loading = true

      const response = await this.internalFetch({ page: this.page, search: this.search })

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
      if (!this.value || (this.multiple && this.selectedOptions.length === this.value.length)
        || (!this.multiple && this.selectedOptions[0] === this.value)) {
        return
      }

      this.loading = true

      const response = await this.internalFetch({ missingValue: this.value })
      this.loading = false
      if (!response.error) {
        this.addOptions(response.data)
      }
    },

    async fetchMore($state) {
      this.loading = true
      this.page += 1
      const response = await this.internalFetch({ page: this.page })
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
      if (this.disabled) {
        return
      }

      this.visible = !this.visible
      this.focusSearch()
    },

    focusSearch() {
      if (this.searchable && this.visible) {
        this.$nextTick(() => this.$refs.searchInput.setFocus())
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
