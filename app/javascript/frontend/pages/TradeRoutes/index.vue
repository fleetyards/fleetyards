<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <h1>{{ $t('headlines.cargo') }}</h1>
      </div>
    </div>
    <FilteredList>
      <Paginator
        v-if="tradeRoutes.length"
        slot="pagination"
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
                    {{ route.origin.name }}
                    <br>
                    <small>
                      {{ route.origin.locationLabel }}
                    </small>
                  </h3>
                  {{ $t('labels.tradeRoutes.buy', { uec: $toUEC(route.buyPrice) }) }}
                </div>
              </Panel>
            </div>
            <div class="col-xs-12 col-sm-4 cargo-route-center">
              <h2 class="text-center">
                {{ route.commodity.name }}
              </h2>
              <i class="fa fa-angle-double-right" />
              <div class="profit">
                {{ $toUEC(route.profitPerUnit) }}
                <small class="profit-percent">
                  ({{ route.profitPerUnitPercent }} %)
                </small>
              </div>
            </div>
            <div class="col-xs-12 col-sm-4">
              <Panel :outer-spacing="false">
                <div class="cargo-route-point">
                  <h3>
                    {{ route.destination.name }}
                    <br>
                    <small>
                      {{ route.destination.locationLabel }}
                    </small>
                  </h3>
                  {{ $t('labels.tradeRoutes.sell', { uec: $toUEC(route.sellPrice) }) }}
                </div>
              </Panel>
            </div>
          </div>
        </div>
      </transition-group>
      <EmptyBox v-if="emptyBoxVisible" />
      <Loader
        :loading="loading"
        fixed
      />
    </FilteredList>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import FilteredList from 'frontend/components/FilteredList'
import Filters from 'frontend/mixins/Filters'
import Panel from 'frontend/components/Panel'
import Loader from 'frontend/components/Loader'
import EmptyBox from 'frontend/partials/EmptyBox'
import FilterForm from 'frontend/partials/TradeRoutes/FilterForm'
import Pagination from 'frontend/mixins/Pagination'

export default {
  components: {
    FilteredList,
    Panel,
    Loader,
    EmptyBox,
    FilterForm,
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
    }
  },

  computed: {
    avaiableCargo() {
      return this.cargoShip ? this.cargoShip.cargo * 100 : 1
    },

    emptyBoxVisible() {
      return !this.loading && !this.tradeRoutes.length && (this.isFilterSelected
        || this.$route.query.page)
    },
  },

  watch: {
    $route() {
      this.fetchTradeRoutes()
      this.fetchCargoShip()
    },
  },

  mounted() {
    this.fetchTradeRoutes()
    this.fetchCargoShip()
  },

  methods: {
    async fetchCargoShip() {
      const query = this.$route.query.q || {}

      if (!query.cargoShip) {
        return
      }

      const response = await this.$api.get(`models/${query.cargoShip}`)

      if (!response.errors) {
        this.cargoShip = response.data
      }

      this.setPages(response.meta)
    },

    async fetchTradeRoutes() {
      this.loading = true

      const response = await this.$api.get('trade-routes', {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })

      this.loading = false

      if (!response.errors) {
        this.tradeRoutes = response.data
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
