<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12 col-md-6">
            <h1>{{ $t('headlines.commodities') }}</h1>
          </div>
          <div class="col-xs-12 col-md-6">
            <div class="page-actions">
              <Btn
                :to="{
                  name: 'cargo',
                  query: {
                    q: $store.state.filters['cargo'],
                  },
                }"
                mobile-block
              >
                {{ $t('labels.cargoRoutes') }}
              </Btn>
              <Btn
                :disabled="this.$route.params.id"
                @click.native="save"
              >
                {{ $t('actions.save') }}
              </Btn>
              <Btn @click.native="resetPrices">
                {{ $t('actions.resetPrices') }}
              </Btn>
            </div>
          </div>
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
            v-for="station in filteredTradeHubs"
            :key="station.slug"
            class="col-xs-12 fade-list-item"
          >
            <Panel>
              <div class="row commodity">
                <div class="col-xs-12">
                  <h2>
                    {{ station.name }}
                    <small>
                      {{ stationTypeLabel(station.type) }} {{ station.planet }}
                    </small>
                  </h2>
                  <h3>Buy:</h3>
                  <div class="flex-row">
                    <div
                      v-for="tradeCommodity in station.tradeCommodities.filter(item => item.buy)"
                      :key="tradeCommodity.name"
                      class="col-xs-12 col-sm-6 col-md-4 col-lg-3 form-group"
                    >
                      <label :for="`${station.slug}-${tradeCommodity.slug}`">
                        {{ tradeCommodity.name }}
                      </label>
                      <div class="input-group">
                        <input
                          :id="`${station.slug}-${tradeCommodity.slug}`"
                          v-model="prices[`${station.slug}-${tradeCommodity.slug}-buy`]"
                          class="form-control"
                          min="0"
                          step="0.01"
                          type="number"
                          @change="updatePrices(`${station.slug}-${tradeCommodity.slug}-buy`)"
                        >
                        <span class="input-group-addon">
                          {{ $t('labels.uecPerUnit') }}
                        </span>
                      </div>
                    </div>
                  </div>
                  <h3>Sell:</h3>
                  <div class="flex-row">
                    <div
                      v-for="tradeCommodity in station.tradeCommodities.filter(item => item.sell)"
                      :key="tradeCommodity.name"
                      class="col-xs-12 col-sm-6 col-md-4 col-lg-3 form-group"
                    >
                      <label :for="`${station.slug}-${tradeCommodity.slug}`">
                        {{ tradeCommodity.name }}
                      </label>
                      <div class="input-group">
                        <input
                          :id="`${station.slug}-${tradeCommodity.slug}`"
                          v-model="prices[`${station.slug}-${tradeCommodity.slug}-sell`]"
                          class="form-control"
                          type="number"
                          step="0.01"
                          min="0"
                          @change="updatePrices(`${station.slug}-${tradeCommodity.slug}-sell`)"
                        >
                        <span class="input-group-addon">
                          {{ $t('labels.uecPerUnit') }}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </Panel>
          </div>
        </transition-group>
        <div class="row">
          <div
            v-if="!filteredTradeHubs.length && !tradeHubsLoading && !commoditiesLoading"
            class="col-xs-12"
          >
            <Panel>
              <div class="trade-hubs-blank">
                <h2>No Commodities present</h2>
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
import Btn from 'frontend/components/Btn'
import Panel from 'frontend/components/Panel'
import CargoRoutes from 'frontend/mixins/CargoRoutes'
import Filters from 'frontend/mixins/Filters'
import FilterForm from 'frontend/partials/CargoRoutes/FilterForm'

export default {
  components: {
    Btn,
    Panel,
    FilterForm,
  },
  mixins: [MetaInfo, CargoRoutes, Filters],
  data() {
    return {
      profitRate: 77.4,
      filterVisible: false,
      fullscreen: false,
    }
  },
  computed: {
    filteredTradeHubs() {
      const query = this.$route.query.q || {}
      return this.tradeHubs.filter((hub) => {
        if (!query.tradeHubIn || !query.tradeHubIn.length) {
          return true
        }
        return query.tradeHubIn.includes(hub.slug)
      }).filter((hub) => {
        if (!query.planetIn || !query.planetIn.length) {
          return true
        }
        return query.planetIn.includes(hub.planet)
      }).filter((item) => {
        if (!query.commodityIn || !query.commodityIn.length) {
          return true
        }
        const commodities = item.tradeCommodities.filter(tc => tc.buy || tc.sell).map(tc => tc.slug)
        return query.commodityIn.some(v => commodities.indexOf(v) >= 0)
      })
    },
    toggleFiltersTooltip() {
      if (this.filterVisible) {
        return this.$t('actions.hideFilter')
      }
      return this.$t('actions.showFilter')
    },
  },
  created() {
    if (this.$route.params.id) {
      this.fetch()
    }
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
    async fetch() {
      const response = await this.$api.get(`commodity-prices/${this.$route.params.id}`)
      if (!response.error) {
        this.$store.commit('tradehubs/setPrices', response.data.data)
      }
    },
    resetPrices() {
      this.$confirm({
        text: this.$t('confirm.tradeRoutes.reset'),
        onConfirm: () => {
          this.$store.dispatch('tradehubs/reset')
          this.$router.replace({
            name: 'commodities',
            query: {
              q: this.$route.query.q,
            },
          })
        },
      })
    },
    updatePrices(key) {
      let prices = JSON.parse(JSON.stringify(this.prices))

      if (key.endsWith('buy')) {
        prices = Object.assign({}, prices, {
          [key.replace('buy', 'sell')]: Math.round((prices[key] * this.profitRate) / 100),
        })
      }

      this.$store.commit('tradehubs/setPrices', prices)
      this.$router.replace({
        name: 'commodities',
        query: {
          q: this.$route.query.q,
        },
      })
    },
    async save() {
      const response = await this.$api.post('commodity-prices', {
        data: JSON.stringify(this.prices),
      })
      if (!response.error) {
        this.$store.commit('tradehubs/setPricesID', response.data.id)
        this.$router.replace({
          name: 'commoditiesSaved',
          params: {
            id: response.data.id,
          },
          query: {
            q: this.$route.query.q,
          },
        })
      }
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.$t('title.commodities'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import './styles/index';
</style>
