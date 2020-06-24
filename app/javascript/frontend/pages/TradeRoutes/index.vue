<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <h1>{{ title }}</h1>
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
          <Btn
            :active="sortByProfit"
            size="small"
            :to="sortBy('profit_per_unit')"
            :exact="true"
          >
            <i class="far fa-dollar-sign" />
            {{ $t('labels.tradeRoutes.sortByProfit') }}
          </Btn>
          <Btn
            :active="sortByPercent"
            size="small"
            :to="sortBy('profit_per_unit_percent')"
            :exact="true"
          >
            <i class="far fa-percent" />
            {{ $t('labels.tradeRoutes.sortByPercent') }}
          </Btn>
          <Btn
            :active="sortByStation"
            size="small"
            :to="sortBy('origin_shop_station_name')"
            :exact="true"
          >
            {{ $t('labels.tradeRoutes.sortByStation') }}
          </Btn>
        </template>
        <BtnDropdown v-else size="small">
          <Btn
            :active="sortByProfit"
            size="small"
            variant="link"
            :to="sortBy('profit_per_unit')"
            :exact="true"
          >
            <i class="far fa-dollar-sign" />
            {{ $t('labels.tradeRoutes.sortByProfit') }}
          </Btn>
          <Btn
            :active="sortByPercent"
            size="small"
            variant="link"
            :to="sortBy('profit_per_unit_percent')"
            :exact="true"
          >
            <i class="far fa-percent" />
            {{ $t('labels.tradeRoutes.sortByPercent') }}
          </Btn>
          <Btn
            :active="sortByStation"
            size="small"
            variant="link"
            :to="sortBy('origin_shop_station_name')"
            :exact="true"
          >
            {{ $t('labels.tradeRoutes.sortByStation') }}
          </Btn>
        </BtnDropdown>
      </template>

      <FilterForm slot="filter" />

      <template v-slot:default="{ records }">
        <transition-group name="fade-list" class="row" tag="div" :appear="true">
          <QuickFilter v-if="!mobile" key="quickfilter" />
          <div
            v-for="route in records"
            :key="
              `${route.origin.slug}-${route.destination.slug}-${route.commodity.slug}`
            "
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
                    {{
                      $t('labels.tradeRoutes.buy', {
                        uec: profit(route.buyPrice),
                      })
                    }}
                  </div>
                </Panel>
              </div>
              <div class="col-12 col-md-4 cargo-route-center">
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
                    {{
                      $t('labels.tradeRoutes.sell', {
                        uec: profit(route.sellPrice),
                      })
                    }}
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
import FilteredList from 'frontend/components/FilteredList'
import Btn from 'frontend/components/Btn'
import BtnDropdown from 'frontend/components/BtnDropdown'
import Panel from 'frontend/components/Panel'
import FilterForm from 'frontend/partials/TradeRoutes/FilterForm'
import QuickFilter from 'frontend/partials/TradeRoutes/QuickFilter'
import { sortBy } from 'frontend/utils/Sorting'
import tradeRoutesCollection from 'frontend/collections/TradeRoutes'
import modelsCollection from 'frontend/collections/Models'

@Component<TradeRoutes>({
  components: {
    FilteredList,
    Btn,
    BtnDropdown,
    Panel,
    FilterForm,
    QuickFilter,
  },

  mixins: [MetaInfo],
})
export default class TradeRoutes extends Vue {
  collection: TradeRoutesCollection = tradeRoutesCollection

  modelsCollection: ModelsCollection = modelsCollection

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

  get cargoShip(): Model | null {
    return this.modelsCollection.record
  }

  get avaiableCargo(): number {
    return this.cargoShip ? this.cargoShip.cargo * 100 : 1
  }

  get sorts(): string[] {
    return this.$route.query.q?.sorts || []
  }

  get sortByPercent(): boolean {
    return (
      this.sorts.includes('profit_per_unit_percent asc') ||
      this.sorts.includes('profit_per_unit_percent desc')
    )
  }

  get sortByProfit(): boolean {
    return (
      this.sorts.includes('profit_per_unit asc') ||
      this.sorts.includes('profit_per_unit desc')
    )
  }

  get sortByStation(): boolean {
    return (
      this.sorts.includes('origin_shop_station_name asc') ||
      this.sorts.includes('origin_shop_station_name desc') ||
      !this.sorts.length
    )
  }

  @Watch('$route')
  onRouteChange() {
    this.fetchCargoShip()
  }

  mounted() {
    this.fetchCargoShip()
  }

  sortBy(field) {
    return sortBy(this.$route, field)
  }

  profit(value: number): string {
    if (this.cargoShip) {
      return this.$toUEC(value * (this.cargoShip.cargo * 100))
    }

    return this.$toUEC(value, this.$t('labels.uecPerUnit'))
  }

  async fetchCargoShip() {
    const query = this.$route.query.q || {}

    if (!query.cargoShip) {
      return
    }

    await modelsCollection.findBySlug(query.cargoShip)
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
