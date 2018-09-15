
import { mapGetters } from 'vuex'
import I18n from 'frontend/lib/I18n'
import { success } from 'frontend/lib/Noty'

export default {
  mixins: [I18n],
  data() {
    return {
      onSaleHangarChannel: null,
      onSaleChannel: null,
      vehiclesChannel: null,
      appVersionChannel: null,
    }
  },
  computed: {
    ...mapGetters([
      'currentUser',
    ]),
  },
  created() {
    this.setupAppVersionUpdates()
  },
  watch: {
    currentUser() {
      if (this.currentUser) {
        this.setupOnSaleVehiclesUpdates()
        this.setupOnSaleUpdates()
        this.setupHangarUpdates()
      }
    },
  },
  methods: {
    setupAppVersionUpdates() {
      this.appVersionChannel = this.$cable.subscriptions.create({
        channel: 'AppVersionChannel',
      }, {
        received: this.updateAppVersion,
      })
    },
    updateAppVersion(data) {
      this.$store.dispatch('updateAppVersion', JSON.parse(data))
    },
    setupHangarUpdates() {
      this.vehiclesChannel = this.$cable.subscriptions.create({
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
      }
    },
    setupOnSaleVehiclesUpdates() {
      this.onSaleHangarChannel = this.$cable.subscriptions.create({
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
      this.onSaleChannel = this.$cable.subscriptions.create({
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
