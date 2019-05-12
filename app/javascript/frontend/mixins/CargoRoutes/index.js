import { mapGetters } from 'vuex'

export default {
  data() {
    return {
      tradeHubs: [],
      commodities: [],
      modelOptions: [],
      tradeHubsLoading: false,
      commoditiesLoading: false,
    }
  },
  methods: {
    async fetchModels() {
      const response = await this.$api.get('models/cargo-options')
      if (!response.error) {
        this.modelOptions = response.data.map(item => ({
          name: `${item.name} (${this.toNumber(item.cargo, 'cargo')})`,
          value: item.value,
          cargo: item.cargo,
        }))
      }
    },
    async fetchTradeHubs() {
      this.tradeHubsLoading = true
      const response = await this.$api.get('trade-hubs')
      this.tradeHubsLoading = false
      if (!response.error) {
        this.tradeHubs = response.data
        this.tradeHubs.forEach((hub) => {
          hub.tradeCommodities.forEach((tc) => {
            if (!this.prices[`${hub.slug}-${tc.slug}-sell`] && tc.sell) {
              this.prices[`${hub.slug}-${tc.slug}-sell`] = tc.sellPrice
            }
            if (!this.prices[`${hub.slug}-${tc.slug}-buy`] && tc.buy) {
              this.prices[`${hub.slug}-${tc.slug}-buy`] = tc.buyPrice
            }
          })
        })
      }
    },
    async fetchCommodities() {
      this.commoditiesLoading = true
      const response = await this.$api.get('commodities')
      this.commoditiesLoading = false
      if (!response.error) {
        this.commodities = response.data
      }
    },
    stationTypeLabel(type) {
      if (['asteroid_station'].includes(type)) {
        return 'on asteroid near'
      } if (['hub', 'truckstop'].includes(type)) {
        return 'in orbit around'
      }
      return 'on'
    },
  },
  computed: {
    ...mapGetters('tradehubs', [
      'prices',
    ]),
  },
  created() {
    this.fetchModels()
    this.fetchTradeHubs()
    this.fetchCommodities()
  },
}
