<template>
  <router-view v-if="isSubRoute" />
  <section
    v-else
    class="container"
  >
    <div class="row">
      <div class="col-xs-12">
        <h1 class="sr-only">
          {{ t('headlines.stations') }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12 col-md-6">
        <div class="page-actions page-actions-left">
          <Btn
            v-tooltip="toggleFiltersTooltip"
            :active="stationFilterVisible"
            :aria-label="toggleFiltersTooltip"
            small
            @click.native="toggleFilter"
          >
            <i
              :class="{
                fas: isFilterSelected,
                far: !isFilterSelected,
              }"
              class="fa-filter"
            />
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
          v-show="stationFilterVisible"
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
            <StationList
              :item="station"
              :route="{
                name: 'station',
                params: {
                  slug: station.slug
                }
              }"
            >
              <template #stats>
                <dl class="dl-horizontal">
                  <dt>{{ t('labels.station.type') }}:</dt>
                  <dd>{{ station.typeLabel }}</dd>
                  <dt>{{ t('labels.station.location') }}:</dt>
                  <dd>{{ station.location }}</dd>
                  <dt v-if="station.shops.length">
                    {{ t('labels.station.shops') }}:
                  </dt>
                  <dd v-if="station.shops.length">
                    {{ station.shops.map(item => item.name).join(', ') }}
                  </dd>
                  <dt>{{ t('labels.station.docks') }}:</dt>
                  <dd>
                    <template v-if="station.docks.length">
                      <ul class="list-unstyled">
                        <li
                          v-for="(dock, index) in station.docks"
                          :key="index"
                        >
                          {{ dock.size }} {{ dock.typeLabel }}: {{ dock.count }}
                        </li>
                      </ul>
                    </template>
                    <template v-else>
                      {{ t('labels.none') }}
                    </template>
                  </dd>

                  <dt>{{ t('labels.station.habitation') }}:</dt>
                  <dd>
                    <template v-if="station.habitations.length">
                      <ul class="list-unstyled">
                        <li
                          v-for="(habitation, index) in station.habitations"
                          :key="index"
                        >
                          {{ habitation.typeLabel }}: {{ habitation.count }}
                        </li>
                      </ul>
                    </template>
                    <template v-else>
                      {{ t('labels.none') }}
                    </template>
                  </dd>
                </dl>
              </template>
            </StationList>
          </div>
        </transition-group>
        <EmptyBox v-if="emptyBoxVisible" />
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
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Loader from 'frontend/components/Loader'
import StationList from 'frontend/partials/Stations/List'
import EmptyBox from 'frontend/partials/EmptyBox'
import Hash from 'frontend/mixins/Hash'
import Pagination from 'frontend/mixins/Pagination'
import Filters from 'frontend/mixins/Filters'
import FilterForm from 'frontend/partials/Stations/FilterForm'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'

export default {
  components: {
    Loader,
    EmptyBox,
    StationList,
    FilterForm,
    Btn,
  },
  mixins: [I18n, MetaInfo, Hash, Filters, Pagination],
  data() {
    return {
      loading: false,
      stations: [],
      fullscreen: false,
    }
  },
  computed: {
    ...mapGetters([
      'stationFilterVisible',
      'mobile',
    ]),
    isSubRoute() {
      return this.$route.name !== 'stations'
    },
    toggleFiltersTooltip() {
      if (this.stationFilterVisible) {
        return this.t('actions.hideFilter')
      }
      return this.t('actions.showFilter')
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
      this.$store.commit('setStationFilterVisible', false)
    }
    this.toggleFullscreen()
  },
  methods: {
    toggleFullscreen() {
      this.fullscreen = !this.stationFilterVisible
    },
    toggleFilter() {
      this.$store.dispatch('toggleStationFilter')
    },
    async fetch() {
      if (this.isSubRoute) {
        return
      }
      this.loading = true
      const response = await this.$api.get('stations', {
        q: this.$route.query.q,
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
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.stations'),
    })
  },
}
</script>
