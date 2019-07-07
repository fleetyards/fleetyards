<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12 col-md-6">
            <h1>{{ $t('headlines.cargo') }}</h1>
          </div>
          <div class="col-xs-12 col-md-6">
            <div class="page-actions">
              <Btn
                :to="{
                  name: 'commodities',
                  query: {
                    q: $store.state.filters['commodities'],
                  },
                }"
              >
                {{ $t('actions.editCommodities') }}
              </Btn>
            </div>
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
        </div>
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
          class="col-md-3 col-xlg-2"
        >
          <FilterForm
            :trade-hubs="tradeHubs"
            :commodities="commodities"
            :model-options="modelOptions"
          />
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
          class="row"
          tag="div"
          appear
        >
          <div
            v-for="route in cargoRoutes"
            :key="`${route.from.slug}-${route.to.slug}-${route.commodity.slug}`"
            class="col-xs-12 fade-list-item cargo-route"
          >
            <div class="flex-row">
              <div class="col-xs-12 col-sm-4">
                <Panel :outer-spacing="false">
                  <div class="cargo-route-point">
                    <h3>
                      {{ route.from.name }}
                      <br>
                      <small>
                        {{ stationTypeLabel(route.from.type) }} {{ route.from.planet }}
                      </small>
                    </h3>
                    Buy for: {{ route.buyPrice }} {{ uecLabel }}
                  </div>
                </Panel>
              </div>
              <div class="col-xs-12 col-sm-4 cargo-route-center">
                <h2 class="text-center">
                  {{ route.commodity.name }}
                </h2>
                <i class="fa fa-angle-double-right" />
                <div class="profit">
                  {{ route.profit }} {{ uecLabel }}
                  <small class="profit-percent">
                    ({{ route.profitPercent }} %)
                  </small>
                </div>
              </div>
              <div class="col-xs-12 col-sm-4">
                <Panel :outer-spacing="false">
                  <div class="cargo-route-point">
                    <h3>
                      {{ route.to.name }}
                      <br>
                      <small>
                        {{ stationTypeLabel(route.to.type) }} {{ route.to.planet }}
                      </small>
                    </h3>
                    Sell for: {{ route.sellPrice }} {{ uecLabel }}
                  </div>
                </Panel>
              </div>
            </div>
          </div>
        </transition-group>
        <div class="row">
          <div
            v-if="!cargoRoutes.length && !tradeHubsLoading && !commoditiesLoading"
            class="col-xs-12"
          >
            <Panel>
              <div class="cargo-routes-blank">
                <h2>No Trade routes present.</h2>
                <p>
                  Please fill in the prices on at least two Trade Hubs for at least on Commodity.
                </p>
              </div>
            </Panel>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Filters from 'frontend/mixins/Filters'
import Btn from 'frontend/components/Btn'
import Panel from 'frontend/components/Panel'
import FilterForm from 'frontend/partials/CargoRoutes/FilterForm'
import CargoRoutes from 'frontend/mixins/CargoRoutes'

export default {
  components: {
    Btn,
    Panel,
    FilterForm,
  },
  mixins: [MetaInfo, CargoRoutes, Filters],
  data() {
    return {
      filterVisible: false,
      fullscreen: false,
    }
  },
  computed: {
    cargoShip() {
      const query = this.$route.query.q || {}
      return this.modelOptions.find(item => item.value === query.cargoShip)
    },
    uecLabel() {
      return this.cargoShip ? this.$t('labels.uec') : this.$t('labels.uecPerUnit')
    },
    avaiableCargo() {
      return this.cargoShip ? this.cargoShip.cargo * 100 : 1
    },
    toggleFiltersTooltip() {
      if (this.filterVisible) {
        return this.$t('actions.hideFilter')
      }
      return this.$t('actions.showFilter')
    },
    cargoRoutes() {
      const cargoRoutes = []
      this.commodities.forEach((commodity) => {
        this.tradeHubs.forEach((from) => {
          const buyPrice = this.prices[`${from.slug}-${commodity.slug}-buy`]
          if (!buyPrice) {
            return
          }
          this.tradeHubs.filter(station => station.slug !== from.slug).forEach((to) => {
            const sellPrice = this.prices[`${to.slug}-${commodity.slug}-sell`]
            if (!sellPrice) {
              return
            }
            cargoRoutes.push({
              from,
              to,
              commodity,
              buyPrice: Math.round((buyPrice * this.avaiableCargo) * 100) / 100,
              sellPrice: Math.round((sellPrice * this.avaiableCargo) * 100) / 100,
              profitPercent: Math.round(((100 * (sellPrice - buyPrice)) / buyPrice) * 100) / 100,
              profit: Math.round(((sellPrice - buyPrice) * this.avaiableCargo) * 100) / 100,
            })
          })
        })
      })
      const result = cargoRoutes.filter(r => r.profit > 0)

      const query = this.$route.query.q || {}

      if (query.sortBy === 'profit') {
        return this.filter(result.sort(this.sortByProfit))
      }

      return this.filter(result.sort(this.sortByProfitPercent))
    },
  },
  mounted() {
    this.toggleFullscreen()
  },
  methods: {
    toggleFilter() {
      this.filterVisible = !this.filterVisible
    },
    toggleFullscreen() {
      this.fullscreen = !this.filterVisible
    },
    sortByProfitPercent(a, b) {
      if (a.profitPercent > b.profitPercent) {
        return -1
      }

      if (a.profitPercent < b.profitPercent) {
        return 1
      }

      return 0
    },
    sortByProfit(a, b) {
      if (a.profit > b.profit) {
        return -1
      }

      if (a.profit < b.profit) {
        return 1
      }

      return 0
    },
    filter(cargoRoutes) {
      const query = this.$route.query.q || {}
      return cargoRoutes.filter((r) => {
        if (!query.tradeHubIn || !query.tradeHubIn.length) {
          return true
        }
        if (query.tradeHubIn.length > 1) {
          return query.tradeHubIn.includes(r.from.slug) && query.tradeHubIn.includes(r.to.slug)
        }
        return query.tradeHubIn.includes(r.from.slug) || query.tradeHubIn.includes(r.to.slug)
      }).filter((r) => {
        if (!query.planetIn || !query.planetIn.length) {
          return true
        }
        if (query.planetIn.length > 1) {
          return query.planetIn.includes(r.from.planet) && query.planetIn.includes(r.to.planet)
        }
        return query.planetIn.includes(r.from.planet) || query.planetIn.includes(r.to.planet)
      }).filter((r) => {
        if (!query.commodityIn || !query.commodityIn.length) {
          return true
        }
        return query.commodityIn.includes(r.commodity.slug)
      })
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
