<template>
  <section class="container">
    <div class="row">
      <div class="col-12 col-md-8">
        <h1>{{ title }}</h1>
      </div>
      <div class="col-12 col-md-4">
        <div class="page-actions page-actions-right">
          <PriceModalBtn
            commodity-item-type="Commodity"
            :withouth-rental="true"
          />
        </div>
      </div>
    </div>
    <FilteredList
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :hash="$route.hash"
      :paginated="true"
    >
      <template slot="actions">
        <template v-if="!mobile">
          <BtnGroup>
            <Btn
              v-tooltip="$t('labels.tradeRoutes.showLatestPrices')"
              :active="!averagePrices"
              size="small"
              variant="dropdown"
              @click.native="showLatestPrices"
            >
              <i class="far fa-sort-amount-down" />
            </Btn>
            <Btn
              v-tooltip="$t('labels.tradeRoutes.showAveragePrices')"
              :active="averagePrices"
              size="small"
              variant="dropdown"
              @click.native="showAveragePrices"
            >
              <i class="far fa-empty-set" />
            </Btn>
          </BtnGroup>
          <BtnGroup>
            <Btn
              v-tooltip="$t('labels.tradeRoutes.sortByProfit')"
              :active="sortByProfit || sortByAverageProfit"
              size="small"
              variant="dropdown"
              :to="
                averagePrices
                  ? sortBy('average_profit_per_unit', 'desc')
                  : sortBy('profit_per_unit', 'desc')
              "
              :exact="true"
            >
              <i class="far fa-dollar-sign" />
            </Btn>
            <Btn
              v-tooltip="$t('labels.tradeRoutes.sortByPercent')"
              :active="sortByPercent || sortByAveragePercent"
              size="small"
              variant="dropdown"
              :to="
                averagePrices
                  ? sortBy('average_profit_per_unit_percent', 'desc')
                  : sortBy('profit_per_unit_percent', 'desc')
              "
              :exact="true"
            >
              <i class="far fa-percent" />
            </Btn>
            <Btn
              :active="sortByStation"
              size="small"
              variant="dropdown"
              :to="sortBy('origin_shop_station_name', 'asc')"
              :exact="true"
            >
              {{ $t('labels.tradeRoutes.sortByStation') }}
            </Btn>
          </BtnGroup>
        </template>
        <BtnDropdown v-else size="small">
          <Btn
            :active="sortByProfit || sortByAverageProfit"
            size="small"
            variant="dropdown"
            :to="
              averagePrices
                ? sortBy('average_profit_per_unit', 'desc')
                : sortBy('profit_per_unit', 'desc')
            "
            :exact="true"
          >
            <i class="far fa-dollar-sign" />
            <span>{{ $t('labels.tradeRoutes.sortByProfit') }}</span>
          </Btn>
          <Btn
            :active="sortByPercent || sortByAveragePercent"
            size="small"
            variant="dropdown"
            :to="
              averagePrices
                ? sortBy('average_profit_per_unit_percent', 'desc')
                : sortBy('profit_per_unit_percent', 'desc')
            "
            :exact="true"
          >
            <i class="far fa-percent" />
            <span>{{ $t('labels.tradeRoutes.sortByPercent') }}</span>
          </Btn>
          <Btn
            :active="sortByStation"
            size="small"
            variant="dropdown"
            :to="sortBy('origin_shop_station_name', 'asc')"
            :exact="true"
          >
            <i class="fad fa-map-marker-alt" />
            <span>{{ $t('labels.tradeRoutes.sortByStation') }}</span>
          </Btn>
        </BtnDropdown>
      </template>

      <FilterForm slot="filter" />

      <template #default="{ records }">
        <transition-group name="fade-list" class="row" tag="div" :appear="true">
          <QuickFilter v-if="!mobile" key="quickfilter" />
          <div
            v-for="route in records"
            :key="route.id"
            class="col-12 fade-list-item cargo-route"
          >
            <div class="row">
              <div class="col-12 col-md-4">
                <Panel :outer-spacing="false">
                  <div class="cargo-route-point">
                    <h3>
                      <router-link
                        :to="{
                          name: 'station',
                          params: {
                            slug: route.origin.slug,
                          },
                        }"
                      >
                        {{ route.origin.name }}
                      </router-link>
                      <br />
                      <small class="text-muted">
                        {{ route.origin.locationLabel }}
                      </small>
                    </h3>
                    <TradeRoutePrice
                      :trade-route="route"
                      :average="averagePrices"
                      :available-cargo="availableCargo"
                    />
                  </div>
                </Panel>
              </div>
              <div class="col-12 col-md-4 cargo-route-center">
                <h2 class="text-center">
                  {{ route.commodity.name }}
                </h2>
                <i class="fa fa-angle-double-right" />
                <TradeRouteProfit
                  :trade-route="route"
                  :average="averagePrices"
                  :available-cargo="availableCargo"
                />
              </div>
              <div class="col-12 col-md-4">
                <Panel :outer-spacing="false">
                  <div class="cargo-route-point">
                    <h3>
                      <router-link
                        :to="{
                          name: 'station',
                          params: {
                            slug: route.destination.slug,
                          },
                        }"
                      >
                        {{ route.destination.name }}
                      </router-link>
                      <br />
                      <small class="text-muted">
                        {{ route.destination.locationLabel }}
                      </small>
                    </h3>
                    <TradeRoutePrice
                      price-type="sell"
                      :trade-route="route"
                      :average="averagePrices"
                      :available-cargo="availableCargo"
                    />
                  </div>
                </Panel>
              </div>
            </div>
          </div>
        </transition-group>
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FilteredList from 'frontend/core/components/FilteredList'
import Btn from 'frontend/core/components/Btn'
import BtnGroup from 'frontend/core/components/BtnGroup'
import PriceModalBtn from 'frontend/components/ShopCommodities/PriceModalBtn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import Panel from 'frontend/core/components/Panel'
import FilterForm from 'frontend/components/TradeRoutes/FilterForm'
import QuickFilter from 'frontend/components/TradeRoutes/QuickFilter'
import TradeRoutePrice from 'frontend/components/TradeRoutes/Price'
import TradeRouteProfit from 'frontend/components/TradeRoutes/Profit'
import { sortBy } from 'frontend/utils/Sorting'
import tradeRoutesCollection from 'frontend/api/collections/TradeRoutes'
import modelsCollection from 'frontend/api/collections/Models'

@Component<TradeRoutes>({
  components: {
    FilteredList,
    Btn,
    BtnGroup,
    PriceModalBtn,
    BtnDropdown,
    Panel,
    FilterForm,
    QuickFilter,
    TradeRoutePrice,
    TradeRouteProfit,
  },

  mixins: [MetaInfo],
})
export default class TradeRoutes extends Vue {
  collection: TradeRoutesCollection = tradeRoutesCollection

  modelsCollection: ModelsCollection = modelsCollection

  averagePrices: boolean = false

  cargoShip: Model | null = null

  @Getter('mobile') mobile

  get title(): string {
    if (this.cargoShip) {
      return this.$t('headlines.tradeRoutes.withShip', {
        name: `${this.cargoShip.manufacturer.code} ${this.cargoShip.name}`,
        cargo: this.$toNumber(this.cargoShip.cargo, 'cargo'),
      })
    }

    return this.$t('headlines.tradeRoutes.index')
  }

  get availableCargo(): number {
    return this.cargoShip ? this.cargoShip.cargo * 100 : null
  }

  get sorts(): string[] {
    return this.$route.query.q?.sorts || []
  }

  get sortByAveragePercent(): boolean {
    return (
      this.sorts.includes('average_profit_per_unit_percent asc') ||
      this.sorts.includes('average_profit_per_unit_percent desc')
    )
  }

  get sortByPercent(): boolean {
    return (
      this.sorts.includes('profit_per_unit_percent asc') ||
      this.sorts.includes('profit_per_unit_percent desc')
    )
  }

  get sortByAverageProfit(): boolean {
    return (
      this.sorts.includes('average_profit_per_unit asc') ||
      this.sorts.includes('average_profit_per_unit desc')
    )
  }

  get sortByProfit(): boolean {
    return (
      this.sorts.includes('profit_per_unit asc') ||
      this.sorts.includes('profit_per_unit desc') ||
      !this.sorts.length
    )
  }

  get sortByStation(): boolean {
    return (
      this.sorts.includes('origin_shop_station_name asc') ||
      this.sorts.includes('origin_shop_station_name desc')
    )
  }

  @Watch('$route')
  onRouteChange() {
    this.fetchCargoShip()
  }

  mounted() {
    this.averagePrices = this.sortByAverageProfit || this.sortByAveragePercent
    this.fetchCargoShip()
  }

  sortBy(field, direction) {
    return sortBy(this.$route, field, direction)
  }

  showLatestPrices() {
    this.averagePrices = false

    if (this.sortByProfit || this.sortByAverageProfit) {
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      this.$router.push(this.sortBy('profit_per_unit', 'desc')).catch(() => {})
    } else if (this.sortByPercent || this.sortByAveragePercent) {
      this.$router
        .push(this.sortBy('profit_per_unit_percent', 'desc'))
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        .catch(() => {})
    }
  }

  showAveragePrices() {
    this.averagePrices = true

    if (this.sortByProfit || this.sortByAverageProfit) {
      this.$router
        .push(this.sortBy('average_profit_per_unit', 'desc'))
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        .catch(() => {})
    } else if (this.sortByPercent || this.sortByAveragePercent) {
      this.$router
        .push(this.sortBy('average_profit_per_unit_percent', 'desc'))
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        .catch(() => {})
    }
  }

  async fetchCargoShip() {
    const query = this.$route.query.q || {}

    if (!query.cargoShip) {
      this.cargoShip = null
      return
    }

    this.cargoShip = await modelsCollection.findBySlug(query.cargoShip)
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
