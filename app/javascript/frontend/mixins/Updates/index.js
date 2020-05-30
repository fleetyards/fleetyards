import { mapGetters } from 'vuex'
import { I18n } from 'frontend/lib/I18n'

export default {
  mixins: [I18n],

  data() {
    return {
      channels: {},
    }
  },

  computed: {
    ...mapGetters('session', ['isAuthenticated']),
  },

  mounted() {
    this.setupAppVersionUpdates()
    this.setupUpdates()
  },

  beforeDestroy() {
    Object.keys(this.channels).forEach(channel => {
      this.channels[channel].unsubscribe()
    })
  },

  watch: {
    isAuthenticated(value) {
      if (value) {
        this.disconnectUpdates()
        this.$cable.refresh()
        this.setupUpdates()
      } else {
        this.disconnectUpdates()
        this.$cable.refresh()
      }
    },
  },

  methods: {
    setupUpdates() {
      if (this.isAuthenticated) {
        this.setupOnSaleVehiclesUpdates()
        this.setupOnSaleUpdates()
        this.setupHangarCreateUpdates()
        this.setupHangarDestroyUpdates()
      }
    },

    disconnectUpdates() {
      if (this.channels.hangarCreate) {
        this.$cable.consumer.subscriptions.remove(this.channels.hangarCreate)
        this.channels.hangarCreate.unsubscribe()
        delete this.channels.hangarCreate
      }

      if (this.channels.hangarDestroy) {
        this.$cable.consumer.subscriptions.remove(this.channels.hangarDestroy)
        this.channels.hangarDestroy.unsubscribe()
        delete this.channels.hangarDestroy
      }

      if (this.channels.onSaleHangar) {
        this.$cable.consumer.subscriptions.remove(this.channels.onSaleHangar)
        this.channels.onSaleHangar.unsubscribe()
        delete this.channels.onSaleHangar
      }

      if (this.channels.onSale) {
        this.$cable.consumer.subscriptions.remove(this.channels.onSale)
        this.channels.onSale.unsubscribe()
        delete this.channels.onSale
      }
    },

    setupAppVersionUpdates() {
      this.channels.appVersion = this.$cable.consumer.subscriptions.create(
        {
          channel: 'AppVersionChannel',
        },
        {
          received: this.updateAppVersion,
          connected: () => {
            this.connected('AppVersionChannel')
          },
          disconnected: () => {
            this.disconnected('AppVersionChannel')
          },
        },
      )
    },

    updateAppVersion(data) {
      this.$store.dispatch('app/updateVersion', JSON.parse(data))
    },

    setupHangarCreateUpdates() {
      if (this.channels.hangarCreate) {
        return
      }
      this.channels.hangarCreate = this.$cable.consumer.subscriptions.create(
        {
          channel: 'HangarCreateChannel',
        },
        {
          received: this.addShipToHangar,
          connected: () => {
            this.connected('HangarCreateChannel')
          },
          disconnected: () => {
            this.disconnected('HangarCreateChannel')
          },
        },
      )
    },

    setupHangarDestroyUpdates() {
      if (this.channels.hangarDestroy) {
        return
      }
      this.channels.hangarDestroy = this.$cable.consumer.subscriptions.create(
        {
          channel: 'HangarDestroyChannel',
        },
        {
          received: this.removeShipFromHangar,
          connected: () => {
            this.connected('HangarDestroyChannel')
          },
          disconnected: () => {
            this.disconnected('HangarDestroyChannel')
          },
        },
      )
    },

    addShipToHangar(data) {
      const vehicle = JSON.parse(data)

      if (!vehicle.model) {
        return
      }

      this.$store.dispatch('hangar/add', vehicle.model.slug)
    },

    removeShipFromHangar(data) {
      const vehicle = JSON.parse(data)

      if (!vehicle.model) {
        return
      }

      this.$store.dispatch('hangar/remove', vehicle.model.slug)
    },

    notifyVehicleOnSale(data) {
      const vehicle = JSON.parse(data)

      this.$info({
        text: I18n.t('messages.model.onSale', {
          model: vehicle.model.name,
        }),
        icon: vehicle.model.storeImageSmall,
      })
    },

    notifyOnSale(data) {
      const model = JSON.parse(data)

      this.$info({
        text: I18n.t('messages.model.onSale', { model: model.name }),
        icon: model.storeImageSmall,
      })
    },

    setupOnSaleVehiclesUpdates() {
      if (this.channels.onSaleHangar) {
        return
      }
      this.channels.onSaleHangar = this.$cable.consumer.subscriptions.create(
        {
          channel: 'OnSaleHangarChannel',
        },
        {
          received: this.notifyVehicleOnSale,
          connected: () => {
            this.connected('OnSaleHangarChannel')
          },
          disconnected: () => {
            this.disconnected('OnSaleHangarChannel')
          },
        },
      )
    },

    setupOnSaleUpdates() {
      if (this.channels.onSale) {
        return
      }
      this.channels.onSale = this.$cable.consumer.subscriptions.create(
        {
          channel: 'OnSaleChannel',
        },
        {
          received: this.notifyOnSale,
          connected: () => {
            this.connected('OnSaleChannel')
          },
          disconnected: () => {
            this.disconnected('OnSaleChannel')
          },
        },
      )
    },
    connected(_channel) {
      // console.info('Connected to', channel)
    },
    disconnected(_channel) {
      // console.info('Disconnected from', channel)
    },
  },
}
