<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12 filtered-header">
          <div class="filtered-header-left">
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
          <div class="filtered-header-right">
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
            :primary-key="collection.primaryKey"
            :empty-box-visible="emptyBoxVisible"
          />

          <EmptyBox v-if="!hideEmptyBox" :visible="emptyBoxVisible" />

          <Loader v-if="!hideLoading" :loading="loading" :fixed="true" />
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <slot name="pagination-bottom">
            <Paginator
              v-if="paginated && collection.records.length"
              :collection="collection"
              :page="page"
            />
          </slot>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions, mapMutations } from 'vuex'
import Btn from '@/frontend/core/components/Btn/index.vue'
import Paginator from '@/frontend/core/components/Paginator/index.vue'
import Loader from '@/frontend/core/components/Loader/index.vue'
import EmptyBox from '@/frontend/core/components/EmptyBox/index.vue'
import { scrollToAnchor } from '@/frontend/utils/scrolling'
import { isFilterSelected } from '@/frontend/utils/Filters'

export default {
  name: 'FilteredList',

  components: {
    Btn,
    EmptyBox,
    Loader,
    Paginator,
  },

  props: {
    alwaysFilterVisible: {
      type: Boolean,
      default: false,
    },

    collection: {
      required: true,
      type: Object,
    },

    collectionMethod: {
      default: 'findAll',
      type: String,
    },

    hash: {
      type: String,
      default: null,
    },

    hideEmptyBox: {
      default: false,
      type: Boolean,
    },

    hideLoading: {
      default: false,
      type: Boolean,
    },

    name: {
      required: true,
      type: String,
    },

    paginated: {
      type: Boolean,
      default: false,
    },

    params: {
      type: Object,
      default() {
        return {}
      },
    },

    recordListClass: {
      type: String,
      default: null,
    },

    routeFilterName: {
      default: 'q',
      type: String,
    },

    routeQuery: {
      type: Object,
      default: null,
    },
  },

  data() {
    return {
      fullscreen: false,

      loading: true,
    }
  },

  computed: {
    ...mapGetters(['mobile', 'filtersVisible']),

    emptyBoxVisible() {
      return !!(
        !this.loading &&
        !this.collection.records.length &&
        (this.isFilterSelected || (this.paginated && this.page))
      )
    },

    filters() {
      return this.routeQuery[this.routeFilterName]
    },

    filterTooltip() {
      if (this.filterVisible) {
        return this.$t('actions.hideFilter')
      }

      return this.$t('actions.showFilter')
    },

    filterVisible() {
      return !!this.filtersVisible[this.name] && this.hasFilterSlot
    },

    hasFilterSlot() {
      return !!this.$slots.filter
    },

    isFilterSelected() {
      return isFilterSelected(this.filters)
    },

    page() {
      return parseInt(this.routeQuery.page, 10) || 1
    },

    search() {
      return this.routeQuery.search
    },
  },

  watch: {
    filters: {
      deep: true,
      handler() {
        this.saveFilters()
      },
    },

    routeQuery() {
      this.fetch()
    },
  },

  mounted() {
    this.fetch()

    if (this.mobile) {
      this.setFiltersVisible({
        [this.name]: false,
      })
    } else if (this.alwaysFilterVisible) {
      this.setFiltersVisible({
        [this.name]: true,
      })
    }

    this.toggleFullscreen()
    this.saveFilters()

    this.$comlink.$on('filteredListUpdate', this.fetch)
  },

  created() {
    if (this.collection.records.length) {
      // eslint-disable-next-line vue/no-mutating-props
      this.collection.records = []
    }
  },

  beforeDestroy() {
    this.$comlink.$off('filteredListUpdate')
  },

  methods: {
    ...mapActions(['toggleFilterVisible']),
    ...mapMutations(['setFiltersVisible', 'setFilters']),

    async fetch() {
      this.loading = true

      let params = {
        filters: this.filters,
        search: this.search,
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

      setTimeout(() => {
        this.loading = false
      }, 300)
    },

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
    },

    toggleFilter() {
      this.toggleFilterVisible(this.name)
    },

    toggleFullscreen() {
      this.fullscreen = !this.filterVisible
    },
  },
}
</script>
