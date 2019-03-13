
import { mapGetters } from 'vuex'
import I18n from 'frontend/lib/I18n'
import { success } from 'frontend/lib/Noty'

export default {
  mixins: [I18n],
  data() {
    return {
      channels: {},
    }
  },
  computed: {
    ...mapGetters([
      'currentUser',
    ]),
  },
  mounted() {
    this.setupAppVersionUpdates()
    this.setupUpdates()
  },
  beforeDestroy() {
    Object.keys(this.channels).forEach((channel) => {
      this.channels[channel].unsubscribe()
    })
  },
  watch: {
    currentUser() {
      this.setupUpdates()
    },
  },
  methods: {
    setupUpdates() {
      if (this.currentUser) {
        this.setupOnSaleVehiclesUpdates()
        this.setupOnSaleUpdates()
        this.setupHangarUpdates()
      }
    },
    setupAppVersionUpdates() {
      this.channels.appVersion = this.$cable.subscriptions.create({
        channel: 'AppVersionChannel',
      }, {
        received: this.updateAppVersion,
      })
    },
    updateAppVersion(data) {
      this.$store.dispatch('updateAppVersion', JSON.parse(data))
    },
    setupHangarUpdates() {
      this.channels.vehicles = this.$cable.subscriptions.create({
        channel: 'HangarChannel',
        username: this.currentUser.username,
      }, {
        received: this.updateHangar,
      })
    },
    updateHangar(data) {
      const vehicle = JSON.parse(data)
      if (vehicle.deleted) {
        this.$store.commit('removeFromHangar', vehicle.model.slug)
      } else {
        this.$store.commit('addToHangar', vehicle.model.slug)
      }
    },
    setupOnSaleVehiclesUpdates() {
      this.channels.onSaleHangar = this.$cable.subscriptions.create({
        channel: 'OnSaleHangarChannel',
        username: this.currentUser.username,
      }, {
        received(data) {
          const vehicle = JSON.parse(data)
          success(I18n.t('messages.model.onSale', { model: vehicle.model.name }))
        },
      })
    },
    setupOnSaleUpdates() {
      this.channels.onSale = this.$cable.subscriptions.create({
        channel: 'OnSaleChannel',
      }, {
        received(data) {
          const model = JSON.parse(data)
          success(I18n.t('messages.model.onSale', { model: model.name }))
        },
      })
    },
  },
}
