<template>
  <div ref="filterGroup" class="filter-group" :class="cssClasses">
    <transition name="fade">
      <label v-show="labelVisible" v-if="innerLabel && !noLabel" :for="id">
        {{ innerLabel }}
      </label>
    </transition>
    <div
      v-tooltip.right="error"
      :class="{
        active: visible,
        disabled,
        selected: selectedOptions.length > 0,
        hasLabel: labelVisible,
      }"
      class="filter-group-title"
      @click="toggle"
    >
      <span class="filter-group-title-prompt">
        {{ prompt }}
      </span>
      <SmallLoader :loading="loading" />
      <i class="fa fa-chevron-right" />
    </div>
    <BCollapse
      v-if="multiple"
      :id="`${groupID}-${selectedId}`"
      :visible="selectedOptions.length > 0 && !visible"
      class="filter-group-items"
    >
      <a
        v-for="(option, index) in selectedOptions"
        :key="`${groupID}-${selectedId}-${option[valueAttr]}-${index}`"
        :class="{
          active: selected(option[valueAttr]),
          bigIcon,
        }"
        class="filter-group-item fade-list-item"
        @click="select(option[valueAttr])"
      >
        <span v-if="option[iconAttr]" class="filter-group-item-icon">
          <img :src="option[iconAttr]" :alt="`icon-${iconAttr}`" />
        </span>
        <span v-html="option[labelAttr]" />
        <span v-if="multiple">
          <i class="fal fa-plus" />
        </span>
      </a>
    </BCollapse>
    <BCollapse
      :id="`${groupID}-${id}`"
      :visible="visible"
      class="filter-group-items-wrapper"
    >
      <FormInput
        v-if="searchable"
        id="search-input"
        ref="searchInput"
        v-model="search"
        :placeholder="searchLabel || $t('actions.find')"
        :label="$t('actions.find')"
        class="filter-group-search"
        variant="clean"
        :no-label="true"
        :clearable="true"
        @input="onSearch"
      />
      <div class="filter-group-items">
        <a
          v-for="(option, index) in filteredOptions"
          :key="`${groupID}-${id}-${option[valueAttr]}-${index}`"
          :class="{
            active: selected(option[valueAttr]),
            bigIcon,
          }"
          class="filter-group-item fade-list-item"
          @click="select(returnObject ? option : option[valueAttr])"
        >
          <span v-if="option[iconAttr]" class="filter-group-item-icon">
            <img :src="option[iconAttr]" :alt="`icon-${iconAttr}`" />
          </span>
          <span v-html="option[labelAttr]" />
          <span v-if="multiple">
            <i class="fal fa-plus" />
          </span>
        </a>

        <InfiniteLoading
          v-if="fetchedOptions.length && !search && paginated"
          ref="infiniteLoading"
          :distance="100"
          @infinite="fetchMore"
        >
          <span slot="no-more" />
          <span slot="spinner" />
        </InfiniteLoading>
      </div>
    </BCollapse>
  </div>
</template>

<script>
import { BCollapse } from 'bootstrap-vue'
import SmallLoader from '@/frontend/core/components/SmallLoader'
import FormInput from '@/frontend/core/components/Form/FormInput'
import debounce from 'lodash.debounce'
import InfiniteLoading from 'vue-infinite-loading'

export default {
  name: 'CollectionFilterGroup',

  components: {
    BCollapse,
    SmallLoader,
    InfiniteLoading,
    FormInput,
  },

  props: {
    // eslint-disable-next-line vue/require-prop-types
    collection: {
      required: true,
    },

    collectionMehtod: {
      type: String,
      default: 'findAll',
    },

    collectionFilter: {
      type: Object,
      default() {
        return {}
      },
    },

    name: {
      required: true,
      type: String,
    },

    value: {
      type: [Array, String, Number],
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

    disabeld: {
      type: Boolean,
      default: false,
    },

    searchable: {
      type: Boolean,
      default: false,
    },

    error: {
      type: String,
      default: null,
    },

    returnObject: {
      type: Boolean,
      default: false,
    },

    nullable: {
      type: Boolean,
      default: true,
    },

    paginated: {
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

    translationKey: {
      type: String,
      default: 'filterGroup',
    },

    noLabel: {
      type: Boolean,
      default: false,
    },

    bigIcon: {
      type: Boolean,
      default: false,
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
      selectedId: null,
      id: null,
      fetchedOptions: [],
      onSearch: debounce(this.debouncedOnSearch, 500),
    }
  },

  computed: {
    prompt() {
      if (this.multiple) {
        return this.label
      }

      if (this.selectedOptions.length > 0) {
        return this.selectedOptions[0][this.labelAttr]
      }

      if (this.nullable) {
        return this.$t(`labels.${this.translationKey}.nullablePrompt`)
      }

      return this.$t(`labels.${this.translationKey}.prompt`)
    },
    labelVisible() {
      return !this.hideLabelOnEmpty || this.selectedOptions.length > 0
    },
    innerLabel() {
      if (this.label) {
        return this.label
      }

      if (this.translationKey && this.translationKey !== 'filterGroup') {
        return this.$t(`labels.${this.translationKey}.label`)
      }

      return this.$t(`labels.${this.id}`)
    },
    groupID() {
      return `${this.name}-${this._uid.toString()}`
    },
    availableOptions() {
      if (this.paginated) {
        return this.sort(this.fetchedOptions)
      }
      return this.fetchedOptions
    },
    selectedOptions() {
      if (this.multiple) {
        return this.availableOptions.filter(
          (item) => this.value && this.value.includes(item[this.valueAttr])
        )
      }
      const selectedOption = this.availableOptions.find(
        (item) => item[this.valueAttr] === this.value
      )
      return selectedOption ? [selectedOption] : []
    },

    filteredOptions() {
      if (this.search) {
        return this.availableOptions.filter((item) =>
          item[this.labelAttr].toLowerCase().includes(this.search.toLowerCase())
        )
      }
      return this.availableOptions
    },

    cssClasses() {
      return {
        'has-error has-feedback': this.error,
      }
    },
  },

  watch: {
    collectionFilter: {
      deep: true,
      handler(newValue, oldValue) {
        if (
          Object.entries(newValue).toString() !==
          Object.entries(oldValue).toString()
        ) {
          this.fetchedOptions = []
          this.fetchOptions()
        }
      },
    },
    disabled() {
      this.fetchOptions()
    },
  },

  created() {
    this.selectedId = this._uid.toString()
    this.id = this._uid.toString()

    document.addEventListener('click', this.documentClick)
  },

  mounted() {
    this.fetchOptions()
  },

  destroyed() {
    document.removeEventListener('click', this.documentClick)
  },

  methods: {
    queryParams(args) {
      const query = {
        filters: {
          ...this.collectionFilter,
        },
      }
      if (args.search && this.searchable) {
        query.filters.nameCont = args.search
      } else if (args.missingValue && this.paginated) {
        query.filters[`${this.valueAttr}Eq`] = args.missingValue
      } else if (args.page && this.paginated) {
        query.page = args.page
      }

      return query
    },

    documentClick(event) {
      const element = this.$refs.filterGroup
      const { target } = event

      if (element !== target && !element.contains(target)) {
        this.visible = false
      }
    },

    debouncedOnSearch() {
      if (this.paginated && this.search) {
        this.page = 1
        this.fetchOptions()
      }
    },

    async fetchOptions() {
      if (this.disabled) {
        this.fetchMissingOption()
        return
      }

      this.loading = true

      const options = await this.collection[this.collectionMethod]({
        ...this.queryParams({
          page: this.page,
          search: this.search,
        }),
        cacheId: this.groupID,
      })

      this.$emit('loaded', options)

      this.loading = false

      if (this.$refs.infiniteLoading) {
        this.$refs.infiniteLoading.$emit('infinite-loading-reset')
      }

      if (options) {
        this.addOptions(options)
        this.fetchMissingOption()
      }
    },

    async fetchMissingOption() {
      if (
        !this.value ||
        (this.multiple && this.selectedOptions.length === this.value.length) ||
        (!this.multiple && this.selectedOptions[0] === this.value)
      ) {
        return
      }

      this.loading = true

      const options = await this.collection[this.collectionMethod]({
        ...this.queryParams({
          missingValue: this.value,
        }),
        cacheId: `${this.groupID}-missing`,
      })

      this.loading = false
      if (options.length) {
        this.addOptions(options)
      }
    },

    async fetchMore($state) {
      this.loading = true
      this.page += 1

      const options = await this.collection[this.collectionMethod](
        this.queryParams({
          page: this.page,
        })
      )

      $state.loaded()

      this.loading = false

      if (options.length) {
        this.addOptions(options)
      } else {
        $state.complete()
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
        if (
          !this.availableOptions.find(
            (option) => option[this.valueAttr] === item[this.valueAttr]
          )
        ) {
          this.fetchedOptions.push(item)
        }
      })
    },

    clearSearch() {
      this.search = null
    },

    selected(option) {
      if (this.multiple) {
        return this.value && this.value.includes(option)
      }

      return this.value === option
    },

    select(option) {
      this.clearSearch()

      if (this.selected(option)) {
        if (this.multiple) {
          this.$emit(
            'input',
            this.value.filter((item) => item !== option)
          )
        } else if (this.nullable) {
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
      this.$emit(
        'input',
        this.value.filter((item) => item !== option)
      )
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
        this.$nextTick(() => {
          if (this.$refs.searchInput) {
            this.$refs.searchInput.setFocus()
          }
        })
      }
    },
  },
}
</script>
