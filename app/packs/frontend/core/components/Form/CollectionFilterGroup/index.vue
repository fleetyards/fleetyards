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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import { BCollapse } from 'bootstrap-vue'
import SmallLoader from 'frontend/core/components/SmallLoader'
import FormInput from 'frontend/core/components/Form/FormInput'
import debounce from 'lodash.debounce'
import InfiniteLoading from 'vue-infinite-loading'

@Component<CollectionFilterGroup>({
  components: {
    BCollapse,
    SmallLoader,
    InfiniteLoading,
    FormInput,
  },
})
export default class CollectionFilterGroup extends Vue {
  visible: boolean = false

  search: string | null = null

  page: number = 1

  loading: boolean = false

  selectedId: string = null

  id: string = null

  fetchedOptions: FilterGroupOption[] = []

  onSearch: Function = debounce(this.debouncedOnSearch, 500)

  @Prop({ required: true }) collection!: BaseCollection

  @Prop({ default: 'findAll' }) collectionMethod: string

  @Prop({
    default: () => ({}),
  })
  collectionFilter!: Object

  @Prop({ required: true }) name!: string

  @Prop({
    default() {
      if (this.multiple) {
        return []
      }
      return null
    },
  })
  value!: string[] | string | number | Object | null

  @Prop({ default: 'value' }) valueAttr!: string

  @Prop({ default: 'name' }) labelAttr!: string

  @Prop({ default: 'icon' }) iconAttr!: string

  @Prop({ default: false }) multiple!: boolean

  @Prop({ default: false }) disabled!: boolean

  @Prop({ default: false }) searchable!: boolean

  @Prop({ default: false }) returnObject!: boolean

  @Prop({ default: true }) nullable!: boolean

  @Prop({ default: null }) error!: string

  @Prop({ default: false }) paginated!: boolean

  @Prop({ default: false }) hideLabelOnEmpty!: boolean

  @Prop({ default: null }) label!: string | null

  @Prop({ default: 'filterGroup' }) translationKey!: string

  @Prop({ default: false }) noLabel!: boolean

  @Prop({ default: false }) bigIcon!: boolean

  @Prop({ default: null }) searchLabel!: string | null

  get prompt() {
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
  }

  get labelVisible() {
    return !this.hideLabelOnEmpty || this.selectedOptions.length > 0
  }

  get innerLabel() {
    if (this.label) {
      return this.label
    }

    if (this.translationKey && this.translationKey !== 'filterGroup') {
      return this.$t(`labels.${this.translationKey}.label`)
    }

    return this.$t(`labels.${this.id}`)
  }

  get groupID() {
    return `${this.name}-${this._uid.toString()}`
  }

  get availableOptions() {
    if (this.paginated) {
      return this.sort(this.fetchedOptions)
    }
    return this.fetchedOptions
  }

  get selectedOptions() {
    if (this.multiple) {
      return this.availableOptions.filter(
        item => this.value && this.value.includes(item[this.valueAttr]),
      )
    }
    const selectedOption = this.availableOptions.find(
      item => item[this.valueAttr] === this.value,
    )
    return selectedOption ? [selectedOption] : []
  }

  get filteredOptions() {
    if (this.search) {
      return this.availableOptions.filter(item =>
        item[this.labelAttr].toLowerCase().includes(this.search.toLowerCase()),
      )
    }
    return this.availableOptions
  }

  get cssClasses() {
    return {
      'has-error has-feedback': this.error,
    }
  }

  @Watch('collectionFilter', { deep: true })
  onCollectionFilterChange() {
    debounce(() => {
      this.fetchedOptions = []
      this.fetchOptions()
    }, 300)
  }

  @Watch('disabled')
  onDisabled() {
    this.fetchOptions()
  }

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
  }

  created() {
    this.selectedId = this._uid.toString()
    this.id = this._uid.toString()

    document.addEventListener('click', this.documentClick)
  }

  mounted() {
    this.fetchOptions()
  }

  destroyed() {
    document.removeEventListener('click', this.documentClick)
  }

  documentClick(event) {
    const element = this.$refs.filterGroup
    const { target } = event

    if (element !== target && !element.contains(target)) {
      this.visible = false
    }
  }

  debouncedOnSearch() {
    if (this.paginated && this.search) {
      this.page = 1
      this.fetchOptions()
    }
  }

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
  }

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
  }

  async fetchMore($state) {
    this.loading = true
    this.page += 1

    const options = await this.collection[this.collectionMethod](
      this.queryParams({
        page: this.page,
      }),
    )

    $state.loaded()

    this.loading = false

    if (options.length) {
      this.addOptions(options)
    } else {
      $state.complete()
    }
  }

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
  }

  addOptions(newOptions) {
    newOptions.forEach(item => {
      if (
        !this.availableOptions.find(
          option => option[this.valueAttr] === item[this.valueAttr],
        )
      ) {
        this.fetchedOptions.push(item)
      }
    })
  }

  clearSearch() {
    this.search = null
  }

  selected(option) {
    if (this.multiple) {
      return this.value && this.value.includes(option)
    }

    return this.value === option
  }

  select(option) {
    this.clearSearch()

    if (this.selected(option)) {
      if (this.multiple) {
        this.$emit(
          'input',
          this.value.filter(item => item !== option),
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
  }

  unselect(option) {
    this.$emit(
      'input',
      this.value.filter(item => item !== option),
    )
  }

  toggle() {
    if (this.disabled) {
      return
    }

    this.visible = !this.visible
    this.focusSearch()
  }

  focusSearch() {
    if (this.searchable && this.visible) {
      this.$nextTick(() => {
        if (this.$refs.searchInput) {
          this.$refs.searchInput.setFocus()
        }
      })
    }
  }
}
</script>
