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
    fetchModels() {
      this.$api.get('models', {}, (args) => {
        if (!args.error) {
          this.modelOptions = args.data.filter(item => item.cargo > 0).map(item => ({
            name: `${item.name} (${this.toNumber(item.cargo, 'cargo')})`,
            value: item.slug,
            cargo: item.cargo,
          }))
        }
      })
    },
    fetchTradeHubs() {
      this.tradeHubsLoading = true
      this.$api.get('trade-hubs', {}, (args) => {
        this.tradeHubsLoading = false
        if (!args.error) {
          this.tradeHubs = args.data
          this.tradeHubs.forEach((hub) => {
            hub.tradeCommodities.forEach((tc) => {
              if (!this.tradeHubPrices[`${hub.slug}-${tc.slug}-sell`] && tc.sell) {
                this.tradeHubPrices[`${hub.slug}-${tc.slug}-sell`] = tc.sellPrice
              }
              if (!this.tradeHubPrices[`${hub.slug}-${tc.slug}-buy`] && tc.buy) {
                this.tradeHubPrices[`${hub.slug}-${tc.slug}-buy`] = tc.buyPrice
              }
            })
          })
        }
      })
    },
    fetchCommodities() {
      this.commoditiesLoading = true
      this.$api.get('commodities', {}, (args) => {
        this.commoditiesLoading = false
        if (!args.error) {
          this.commodities = args.data
        }
      })
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
    ...mapGetters([
      'tradeHubPrices',
    ]),
  },
  created() {
    this.fetchModels()
    this.fetchTradeHubs()
    this.fetchCommodities()
  },
}
