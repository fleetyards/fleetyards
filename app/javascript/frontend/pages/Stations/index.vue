<template>
  <router-view v-if="isSubRoute" />
  <section
    v-else
    class="container"
  >
    <div class="row">
      <div class="col-xs-12">
        <h1 class="sr-only">
          {{ $t('headlines.stations') }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12 col-md-6">
        <div class="page-actions page-actions-left">
          <Btn
            v-tooltip="toggleFiltersTooltip"
            :active="filterVisible"
            :aria-label="toggleFiltersTooltip"
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
      </div>
      <div class="col-xs-12 col-md-6">
        <Paginator
          v-if="stations.length"
          :page="currentPage"
          :total="totalPages"
          right
        />
      </div>
    </div>
    <div class="row">
      <transition
        name="slide"
        appear
        @before-enter="toggleFullscreen"
        @after-leave="toggleFullscreen"
      >
        <div
          v-show="filterVisible"
          class="col-xs-12 col-md-3 col-xlg-2"
        >
          <FilterForm />
        </div>
      </transition>
      <div
        :class="{
          'col-md-9 col-xlg-10': !fullscreen,
        }"
        class="col-xs-12 col-animated"
      >
        <transition-group
          name="fade-list"
          class="flex-row"
          tag="div"
          appear
        >
          <div
            v-for="station in stations"
            :key="station.slug"
            class="col-xs-12 fade-list-item"
          >
            <StationPanel :station="station" />
          </div>
        </transition-group>
        <EmptyBox :visible="emptyBoxVisible" />
        <Loader
          :loading="loading"
          fixed
        />
      </div>
      <div class="col-xs-12">
        <Paginator
          v-if="stations.length"
          :page="currentPage"
          :total="totalPages"
          right
        />
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import StationPanel from 'frontend/components/Stations/Panel'
import EmptyBox from 'frontend/partials/EmptyBox'
import Hash from 'frontend/mixins/Hash'
import Pagination from 'frontend/mixins/Pagination'
import Filters from 'frontend/mixins/Filters'
import FilterForm from 'frontend/partials/Stations/FilterForm'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'

export default {
  name: 'Stations',

  components: {
    Loader,
    EmptyBox,
    StationPanel,
    FilterForm,
    Btn,
  },

  mixins: [
    MetaInfo,
    Hash,
    Filters,
    Pagination,
  ],

  data() {
    return {
      loading: false,
      stations: [],
      fullscreen: false,
    }
  },

  computed: {
    ...mapGetters([
      'mobile',
    ]),

    ...mapGetters('stations', [
      'filterVisible',
    ]),

    isSubRoute() {
      return this.$route.name !== 'stations'
    },

    toggleFiltersTooltip() {
      if (this.filterVisible) {
        return this.$t('actions.hideFilter')
      }
      return this.$t('actions.showFilter')
    },

    emptyBoxVisible() {
      return !this.loading && this.stations.length === 0
    },
  },

  watch: {
    $route() {
      this.fetch()
    },
  },

  created() {
    this.fetch()
    if (this.mobile) {
      this.$store.commit('stations/setFilterVisible', false)
    }
    this.toggleFullscreen()
  },

  methods: {
    toggleFullscreen() {
      this.fullscreen = !this.filterVisible
    },

    toggleFilter() {
      this.$store.dispatch('stations/toggleFilter')
    },

    async fetch() {
      if (this.isSubRoute) {
        return
      }

      this.loading = true
      const response = await this.$api.get('stations', {
        q: {
          ...this.$route.query.q,
          sorts: ['station_type asc', 'name asc'],
        },
        page: this.$route.query.page,
      })

      this.loading = false

      if (!response.error) {
        this.stations = response.data
        this.scrollToAnchor()
      }

      this.setPages(response.meta)
    },
  },
}
</script>
