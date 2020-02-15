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
    ...mapGetters('session', ['currentUser']),
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
    currentUser(value) {
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
      if (this.currentUser) {
        this.setupOnSaleVehiclesUpdates()
        this.setupOnSaleUpdates()
        this.setupHangarUpdates()
      }
    },

    disconnectUpdates() {
      if (this.channels.hangar) {
        this.$cable.consumer.subscriptions.remove(this.channels.hangar)
        this.channels.hangar.unsubscribe()
        delete this.channels.hangar
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

    setupHangarUpdates() {
      if (this.channels.hangar) {
        return
      }
      this.channels.hangar = this.$cable.consumer.subscriptions.create(
        {
          channel: 'HangarChannel',
        },
        {
          received: this.updateHangar,
          connected: () => {
            this.connected('HangarChannel')
          },
          disconnected: () => {
            this.disconnected('HangarChannel')
          },
        },
      )
    },

    updateHangar(data) {
      const vehicle = JSON.parse(data)

      if (!vehicle.model) {
        return
      }

      if (vehicle.deleted) {
        this.$store.dispatch('hangar/remove', vehicle.model.slug)
      } else {
        this.$store.dispatch('hangar/add', vehicle.model.slug)
      }
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
