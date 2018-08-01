<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12 col-md-6">
            <h1>{{ t('headlines.commodities') }}</h1>
          </div>
          <div class="col-xs-12 col-md-6">
            <div class="text-right hidden-md hidden-lg">
              <button
                class="btn btn-link btn-filter"
                @click="openFilter"
              >
                <span v-show="isFilterSelected">
                  <i class="fas fa-filter" />
                </span>
                <span v-show="!isFilterSelected">
                  <i class="fal fa-filter" />
                </span>
              </button>
            </div>
            <div class="page-actions">
              <InternalLink
                :route="{
                  name: 'cargo',
                  query: {
                    q: $store.state.filters['cargo'],
                  },
                }"
                mobile-block
              >
                {{ t('labels.cargoRoutes') }}
              </InternalLink>
              <Btn
                :disabled="this.$route.params.id"
                @click.native="save"
              >
                {{ t('actions.save') }}
              </Btn>
              <Btn @click.native="resetPrices">
                {{ t('actions.resetPrices') }}
              </Btn>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-12 col-md-9">
        <transition-group
          name="fade-list"
          class="row"
          tag="div"
          appear>
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
                          v-model="tradeHubPrices[`${station.slug}-${tradeCommodity.slug}-buy`]"
                          class="form-control"
                          min="0"
                          step="0.01"
                          type="number"
                          @change="updatePrices(`${station.slug}-${tradeCommodity.slug}-buy`)"
                        >
                        <span class="input-group-addon">{{ t('labels.uecPerUnit') }}</span>
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
                          v-model="tradeHubPrices[`${station.slug}-${tradeCommodity.slug}-sell`]"
                          class="form-control"
                          type="number"
                          step="0.01"
                          min="0"
                          @change="updatePrices(`${station.slug}-${tradeCommodity.slug}-sell`)"
                        >
                        <span class="input-group-addon">{{ t('labels.uecPerUnit') }}</span>
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
      <div class="hidden-xs hidden-sm col-md-3">
        <FilterForm />
      </div>
    </div>
    <FilterModal
      ref="filterModal"
      :title="t('headlines.filterCommodities')"
    />
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/components/Btn'
import InternalLink from 'frontend/components/InternalLink'
import Panel from 'frontend/components/Panel'
import CargoRoutes from 'frontend/mixins/CargoRoutes'
import Filters from 'frontend/mixins/Filters'
import FilterModal from 'frontend/partials/CargoRoutes/FilterModal'
import FilterForm from 'frontend/partials/CargoRoutes/FilterForm'
import { confirm } from 'frontend/lib/Noty'

export default {
  components: {
    Btn,
    InternalLink,
    Panel,
    FilterForm,
    FilterModal,
  },
  mixins: [I18n, MetaInfo, CargoRoutes, Filters],
  data() {
    return {
      profitRate: 77.4,
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
  },
  created() {
    if (this.$route.params.id) {
      this.$api.get(`commodity-prices/${this.$route.params.id}`, {}, (args) => {
        if (!args.error) {
          this.$store.commit('setTradeHubPrices', args.data.data)
        }
      })
    }
  },
  methods: {
    openFilter() {
      this.$refs.filterModal.open()
    },
    resetPrices() {
      confirm(this.t('confirm.tradeRoutes.reset'), () => {
        this.$store.commit('resetTradeHubPrices')
        this.$router.replace({
          name: 'commodities',
          query: {
            q: this.$route.query.q,
          },
        })
      })
    },
    updatePrices(key) {
      let prices = JSON.parse(JSON.stringify(this.tradeHubPrices))

      if (key.endsWith('buy')) {
        prices = Object.assign({}, prices, {
          [key.replace('buy', 'sell')]: Math.round((prices[key] * this.profitRate) / 100),
        })
      }

      this.$store.commit('setTradeHubPrices', prices)
      this.$router.replace({
        name: 'commodities',
        query: {
          q: this.$route.query.q,
        },
      })
    },
    save() {
      this.$api.post('commodity-prices', {
        data: JSON.stringify(this.tradeHubPrices),
      }, (args) => {
        if (!args.error) {
          this.$store.commit('setTradeHubPricesID', args.data.id)
          this.$router.replace({
            name: 'commoditiesSaved',
            params: {
              id: args.data.id,
            },
            query: {
              q: this.$route.query.q,
            },
          })
        }
      })
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.commodities'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
