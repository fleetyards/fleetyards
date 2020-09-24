import { mapGetters } from 'vuex'
import { I18n } from 'frontend/lib/I18n'
import { displayInfo } from 'frontend/lib/Noty'

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
    this.setupUpdates()
  },

  beforeDestroy() {
    this.disconnectUpdates()
  },

  watch: {
    isAuthenticated() {
      this.disconnectUpdates()
      this.setupUpdates()
    },
  },

  methods: {
    setupUpdates() {
      this.setupAppVersionChannel()

      if (this.isAuthenticated) {
        this.setupOnSaleVehiclesChannel()
        this.setupOnSaleChannel()
        this.setupHangarCreateChannel()
        this.setupHangarDestroyChannel()
      }
    },

    disconnectUpdates() {
      Object.keys(this.channels).forEach(channel => {
        this.unsubscribeChannel(channel)
      })

      this.$cable.refresh()
    },

    unsubscribeChannel(channel) {
      this.channels[channel].unsubscribe()
      delete this.channels[channel]
    },

    connected(channel) {
      console.info('Connected to Channel:', channel)
    },

    disconnected(channel) {
      this.unsubscribeChannel(channel)
      console.info('Disconnected from Channel:', channel)
    },

    setupAppVersionChannel() {
      this.channels.appVersion = this.$cable.consumer.subscriptions.create(
        {
          channel: 'AppVersionChannel',
        },
        {
          received: this.updateAppVersion,
          connected: () => {
            this.connected('appVersion', this.channels.appVersion)
          },
          disconnected: () => {
            this.disconnected('appVersion')
          },
        },
      )
    },

    setupHangarCreateChannel() {
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
            this.connected('hangarCreate')
          },
          disconnected: () => {
            this.disconnected('hangarCreate')
          },
        },
      )
    },

    setupHangarDestroyChannel() {
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
            this.connected('hangarDestroy')
          },
          disconnected: () => {
            this.disconnected('hangarDestroy')
          },
        },
      )
    },

    setupOnSaleVehiclesChannel() {
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
            this.connected('onSaleHangar')
          },
          disconnected: () => {
            this.disconnected('onSaleHangar')
          },
        },
      )
    },

    setupOnSaleChannel() {
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
            this.connected('onSale')
          },
          disconnected: () => {
            this.disconnected('onSale')
          },
        },
      )
    },

    updateAppVersion(data) {
      this.$store.dispatch('app/updateVersion', JSON.parse(data))
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

      displayInfo({
        text: I18n.t('messages.model.onSale', {
          model: vehicle.model.name,
        }),
        icon: vehicle.model.storeImageSmall,
      })
    },

    notifyOnSale(data) {
      const model = JSON.parse(data)

      displayInfo({
        text: I18n.t('messages.model.onSale', { model: model.name }),
        icon: model.storeImageSmall,
      })
    },
  },
}
