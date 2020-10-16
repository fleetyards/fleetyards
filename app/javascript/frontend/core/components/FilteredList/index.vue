<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12 filtered-list-header">
          <div class="filtered-list-header-left">
            <Btn
              v-if="hasFilterSlot"
              v-tooltip="filterTooltip"
              :active="filterVisible"
              :aria-label="filterTooltip"
              size="small"
              @click.native="toggleFilter"
            >
              <span v-show="isFilterSelected">
                <i class="fas fa-filter" />
              </span>
              <span v-show="!isFilterSelected">
                <i class="far fa-filter" />
              </span>
            </Btn>
          </div>
          <div class="pagination-wrapper">
            <slot name="pagination-top">
              <Paginator
                v-if="paginated && collection.records.length"
                :page="collection.currentPage"
                :total="collection.totalPages"
                :center="true"
              />
            </slot>
          </div>
          <div class="filtered-list-header-right">
            <slot name="actions" :records="collection && collection.records" />
          </div>
        </div>
      </div>
      <div class="row">
        <transition
          name="slide"
          :appear="true"
          @before-enter="toggleFullscreen"
          @after-leave="toggleFullscreen"
        >
          <div v-if="filterVisible" class="col-12 col-lg-3 col-xxl-2">
            <slot name="filter" />
          </div>
        </transition>
        <div
          :class="{
            'col-lg-9 col-xxl-10': !fullscreen,
          }"
          class="col-12 col-animated"
        >
          <slot
            :records="collection && collection.records"
            :filter-visible="filterVisible"
            :loading="loading"
          />

          <transition-group
            name="fade-list"
            class="row"
            tag="div"
            :appear="true"
          >
            <div
              v-for="(record, index) in collection.records"
              :key="record[collection.primaryKey]"
              :class="{
                'col-xxl-3 col-3xl-2dot4': filterVisible,
                'col-xl-3 col-xxl-2dot4 col-3xl-2': !filterVisible,
              }"
              class="col-12 col-md-6 col-lg-4 fade-list-item"
            >
              <slot
                name="record"
                :record="record"
                :index="index"
                :loading="loading"
              />
            </div>
          </transition-group>

          <EmptyBox :visible="emptyBoxVisible" />

          <Loader :loading="loading" :fixed="true" />
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <slot name="pagination-bottom">
            <Paginator
              v-if="paginated && collection.records.length"
              :page="collection.currentPage"
              :total="collection.totalPages"
              :center="true"
            />
          </slot>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch, Prop } from 'vue-property-decorator'
import { Action, Mutation, Getter } from 'vuex-class'
import Btn from 'frontend/core/components/Btn'
import Paginator from 'frontend/core/components/Paginator'
import Loader from 'frontend/core/components/Loader'
import EmptyBox from 'frontend/core/components/EmptyBox'
import { scrollToAnchor } from 'frontend/utils/scrolling'

@Component<FilteredList>({
  components: {
    Btn,
    Paginator,
    Loader,
    EmptyBox,
  },
})
export default class FilteredList extends Vue {
  loading: boolean = true

  fullscreen: boolean = false

  @Prop({ required: true }) collection!: BaseCollection

  @Prop({ required: true }) name!: string

  @Prop({ default: null }) recordListClass!: string

  @Prop({
    default() {
      return {}
    },
  })
  params: RouteParams

  @Prop({ default: 'findAll' }) collectionMethod: string

  @Prop({ default: null }) routeQuery: RouteQuery

  @Prop({ default: null }) hash: string

  @Prop({ default: false }) paginated: boolean

  @Getter('filtersVisible') filtersVisible

  @Getter('mobile') mobile

  @Action('toggleFilterVisible') toggleFilterVisible

  @Mutation('setFiltersVisible') setFiltersVisible

  @Mutation('setFilters') setFilters

  get filters() {
    return this.routeQuery.q
  }

  get hasFilterSlot() {
    return !!this.$slots.filter
  }

  get page() {
    return this.routeQuery.page
  }

  get filterVisible() {
    return !!this.filtersVisible[this.name] && this.hasFilterSlot
  }

  get filterTooltip() {
    if (this.filterVisible) {
      return this.$t('actions.hideFilter')
    }

    return this.$t('actions.showFilter')
  }

  get isFilterSelected() {
    const query = JSON.parse(JSON.stringify(this.filters || {}))
    Object.keys(query)
      .filter(key => !query[key] || query[key].length === 0)
      .forEach(key => delete query[key])
    return Object.keys(query).length > 0
  }

  get emptyBoxVisible() {
    return !!(
      !this.loading &&
      !this.collection.records.length &&
      (this.isFilterSelected || (this.paginated && this.page))
    )
  }

  @Watch('filters', { deep: true })
  onFiltersChange() {
    this.saveFilters()
  }

  @Watch('routeQuery')
  onPageChange() {
    this.fetch()
  }

  mounted() {
    this.fetch()

    if (this.mobile) {
      this.setFiltersVisible({
        [this.name]: false,
      })
    }

    this.toggleFullscreen()
    this.saveFilters()

    this.$comlink.$on('filteredListUpdate', this.fetch)
  }

  beforeDestroy() {
    this.$comlink.$off('filteredListUpdate')
  }

  saveFilters() {
    if (this.isFilterSelected) {
      this.setFilters({
        [this.name]: { ...this.filters },
      })

      return
    }

    this.setFilters({
      [this.name]: null,
    })
  }

  toggleFullscreen() {
    this.fullscreen = !this.filterVisible
  }

  toggleFilter() {
    this.toggleFilterVisible(this.name)
  }

  async fetch() {
    this.loading = true

    let params = {
      filters: this.filters,
    }

    if (this.paginated) {
      params = {
        ...params,
        ...this.params,
        page: this.page,
      }
    }

    if (!this.collection[this.collectionMethod]) {
      throw Error(`Method "${this.collectionMethod}" not found on Collection`)
    }

    await this.collection[this.collectionMethod](params)

    this.$nextTick(() => {
      scrollToAnchor(this.hash)
    })

    this.loading = false
  }
}
</script>
