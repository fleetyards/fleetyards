<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1>{{ title }}</h1>
      </div>
    </div>
    <FilteredList>
      <template slot="actions">
        <Toggle
          size="small"
          :active-left="sortByProfit"
          :active-right="sortByPercent"
          @toggle:left="sortBy('profit')"
          @toggle:right="sortBy('percent')"
        >
          <span
            slot="left"
            v-tooltip="$t('labels.tradeRoutes.sortByProfit')"
          >
            <i class="far fa-dollar-sign" />
          </span>
          <span
            slot="right"
            v-tooltip="$t('labels.tradeRoutes.sortByPercent')"
          >
            <i class="far fa-percent" />
          </span>
        </Toggle>
      </template>
      <Paginator
        v-if="tradeRoutes.length"
        slot="pagination-top"
        :page="currentPage"
        :total="totalPages"
        right
      />
      <FilterForm slot="filter" />
      <transition-group
        name="fade-list"
        class="row"
        tag="div"
        appear
      >
        <QuickFilter
          v-if="!mobile"
          key="quickfilter"
        />
        <div
          v-for="route in tradeRoutes"
          :key="`${route.origin.slug}-${route.destination.slug}-${route.commodity.slug}`"
          class="col-xs-12 fade-list-item cargo-route"
        >
          <div class="flex-row">
            <div class="col-xs-12 col-sm-4">
              <Panel :outer-spacing="false">
                <div class="cargo-route-point">
                  <h3>
                    <router-link
                      :to="{
                        name: 'station',
                        params: {
                          slug: route.origin.slug,
                        }
                      }"
                    >
                      {{ route.origin.name }}
                    </router-link>
                    <br>
                    <small>
                      {{ route.origin.locationLabel }}
                    </small>
                  </h3>
                  {{ $t('labels.tradeRoutes.buy', { uec: profit(route.buyPrice) }) }}
                </div>
              </Panel>
            </div>
            <div class="col-xs-12 col-sm-4 cargo-route-center">
              <h2 class="text-center">
                {{ route.commodity.name }}
              </h2>
              <i class="fa fa-angle-double-right" />
              <div class="profit">
                {{ profit(route.profitPerUnit) }}
                <small class="profit-percent">
                  ({{ route.profitPerUnitPercent }} %)
                </small>
              </div>
            </div>
            <div class="col-xs-12 col-sm-4">
              <Panel :outer-spacing="false">
                <div class="cargo-route-point">
                  <h3>
                    <router-link
                      :to="{
                        name: 'station',
                        params: {
                          slug: route.destination.slug,
                        }
                      }"
                    >
                      {{ route.destination.name }}
                    </router-link>
                    <br>
                    <small>
                      {{ route.destination.locationLabel }}
                    </small>
                  </h3>
                  {{ $t('labels.tradeRoutes.sell', { uec: profit(route.sellPrice) }) }}
                </div>
              </Panel>
            </div>
          </div>
        </div>
      </transition-group>
      <EmptyBox :visible="emptyBoxVisible" />
      <Loader
        :loading="loading"
        fixed
      />
      <Paginator
        v-if="tradeRoutes.length"
        slot="pagination-bottom"
        :page="currentPage"
        :total="totalPages"
        right
      />
    </FilteredList>
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
import { debounce } from 'debounce'

import MetaInfo from 'frontend/mixins/MetaInfo'
import FilteredList from 'frontend/components/FilteredList'
import Toggle from 'frontend/components/Toggle'
import Filters from 'frontend/mixins/Filters'
import Panel from 'frontend/components/Panel'
import Loader from 'frontend/components/Loader'
import EmptyBox from 'frontend/partials/EmptyBox'
import FilterForm from 'frontend/partials/TradeRoutes/FilterForm'
import QuickFilter from 'frontend/partials/TradeRoutes/QuickFilter'
import Pagination from 'frontend/mixins/Pagination'

export default {
  components: {
    FilteredList,
    Toggle,
    Panel,
    Loader,
    EmptyBox,
    FilterForm,
    QuickFilter,
  },

  mixins: [
    MetaInfo,
    Filters,
    Pagination,
  ],

  data() {
    return {
      cargoShip: null,
      tradeRoutes: [],
      loading: true,
      sort: 'profit',
    }
  },

  computed: {
    ...mapGetters([
      'mobile',
    ]),

    title() {
      if (this.cargoShip) {
        return this.$t('headlines.tradeRoutes.withShip', {
          name: `${this.cargoShip.manufacturer.code} ${this.cargoShip.name}`,
          cargo: this.$toNumber(this.cargoShip.cargo, 'cargo'),
        })
      }
      return this.$t('headlines.tradeRoutes.index')
    },

    avaiableCargo() {
      return this.cargoShip ? this.cargoShip.cargo * 100 : 1
    },

    emptyBoxVisible() {
      return !this.loading && !this.tradeRoutes.length && (this.isFilterSelected
        || this.$route.query.page)
    },

    sortByPercent() {
      return this.sort === 'percent'
    },

    sortByProfit() {
      return this.sort === 'profit'
    },
  },

  watch: {
    $route() {
      this.fetch()
      this.fetchCargoShip()
    },
  },

  mounted() {
    this.fetch()
    this.fetchCargoShip()
  },

  methods: {
    sortBy: debounce(function debounced(sort) {
      this.sort = sort

      this.fetch()
    }, 500),

    profit(value) {
      if (this.cargoShip) {
        return this.$toUEC(value * (this.cargoShip.cargo * 100))
      }

      return this.$toUEC(value, this.$t('labels.uecPerUnit'))
    },

    async fetchCargoShip() {
      this.cargoShip = null

      const query = this.$route.query.q || {}

      if (!query.cargoShip) {
        return
      }

      const response = await this.$api.get(`models/${query.cargoShip}`)

      if (!response.errors) {
        this.cargoShip = response.data
      }
    },

    async fetch() {
      this.loading = true

      const response = await this.$api.get('trade-routes', {
        q: {
          ...this.$route.query.q,
        },
        sort: this.sort,
        page: this.$route.query.page,
      })

      this.loading = false

      if (!response.errors) {
        this.tradeRoutes = response.data
      }

      this.setPages(response.meta)
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
