<template>
  <div class="row">
    <div class="col-xs-12">
      <div class="row">
        <div class="col-xs-12 filtered-list-header">
          <div class="page-actions page-actions-left">
            <Btn
              v-if="!hideFilter"
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
          <div class="page-actions page-actions-right">
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
          <div v-if="filterVisible" class="col-xs-12 col-md-3 col-xlg-2">
            <slot v-if="!hideFilter" name="filter" />
          </div>
        </transition>
        <div
          :class="{
            'col-md-9 col-xlg-10': !fullscreen,
          }"
          class="col-xs-12 col-animated"
        >
          <slot
            :filterVisible="filterVisible"
            :records="collection && collection.records"
          />

          <EmptyBox :visible="emptyBoxVisible" />

          <Loader :loading="loading" :fixed="true" />
        </div>
      </div>
      <div class="row">
        <div class="col-xs-12">
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
import Btn from 'frontend/components/Btn'
import Paginator from 'frontend/components/Paginator'
import Loader from 'frontend/components/Loader'
import EmptyBox from 'frontend/partials/EmptyBox'

@Component<FilteredCollectionList>({
  components: {
    Btn,
    Paginator,
    Loader,
    EmptyBox,
  },
})
export default class FilteredCollectionList extends Vue {
  loading: boolean = true

  fullscreen: boolean = false

  @Prop({ required: true }) collection!: BaseCollection

  @Prop({ required: true }) name!: string

  @Prop({ default: null }) routeQuery!: RouteQuery

  @Prop({ default: null }) hash!: string

  @Prop({ default: false }) paginated!: boolean

  @Prop({ default: false }) hideFilter!: boolean

  @Getter('filtersVisible') filtersVisible

  @Getter('mobile') mobile

  @Action('toggleFilterVisible') toggleFilterVisible

  @Mutation('setFiltersVisible') setFiltersVisible

  @Mutation('setFilters') setFilters

  get filters() {
    return this.routeQuery.q
  }

  get page() {
    return this.routeQuery.page
  }

  get filterVisible() {
    return !!this.filtersVisible[this.name] && !this.hideFilter
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
  }

  created() {
    if (this.mobile) {
      this.setFiltersVisible({
        [this.name]: false,
      })
    }

    this.toggleFullscreen()
    this.saveFilters()
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

  scrollToAnchor() {
    if (!this.hash) {
      return
    }

    this.$nextTick(() => {
      const element = document.getElementById(this.hash.slice(1))
      if (element) {
        element.scrollIntoView()
        window.scrollBy(0, -120)
      }
    })
  }

  async fetch() {
    this.loading = true

    let params = {
      filters: this.filters,
    }

    if (this.paginated) {
      params = {
        ...params,
        page: this.page,
      }
    }

    await this.collection.findAll(params)

    this.scrollToAnchor()

    this.loading = false
  }
}
</script>
