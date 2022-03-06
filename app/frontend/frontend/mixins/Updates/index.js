import { mapGetters } from 'vuex'
import { I18n } from '@/frontend/lib/I18n'
import { displayInfo } from '@/frontend/lib/Noty'
import HangarItemsCollection from '@/frontend/api/collections/HangarItems'

export default {
  beforeDestroy() {
    this.disconnectUpdates()
  },

  computed: {
    ...mapGetters('session', ['isAuthenticated']),
  },

  data() {
    return {
      channels: {},
    }
  },

  methods: {
    addShipToHangar(data) {
      const vehicle = JSON.parse(data)

      if (!vehicle.model) {
        return
      }

      this.$store.dispatch('hangar/add', vehicle.model.slug)
    },

    connected(_channel) {
      // console.info('Connected to Channel:', channel)
    },

    disconnected(channel) {
      this.unsubscribeChannel(channel)
      // console.info('Disconnected from Channel:', channel)
    },

    disconnectUpdates() {
      Object.keys(this.channels).forEach((channel) => {
        this.unsubscribeChannel(channel)
      })

      this.$cable.refresh()
    },

    async fetchHangarItems() {
      if (!this.isAuthenticated) {
        return
      }

      await this.$store.dispatch(
        'hangar/saveHangar',
        await HangarItemsCollection.findAll()
      )
    },

    notifyOnSale(data) {
      const model = JSON.parse(data)

      displayInfo({
        icon: model.storeImageSmall,
        text: I18n.t('messages.model.onSale', { model: model.name }),
      })
    },

    notifyVehicleOnSale(data) {
      const vehicle = JSON.parse(data)

      displayInfo({
        icon: vehicle.model.storeImageSmall,
        text: I18n.t('messages.model.onSale', {
          model: vehicle.model.name,
        }),
      })
    },

    removeShipFromHangar(data) {
      const vehicle = JSON.parse(data)

      if (!vehicle.model) {
        return
      }

      this.$store.dispatch('hangar/remove', vehicle.model.slug)
    },

    setupAppVersionChannel() {
      this.channels.appVersion = this.$cable.consumer.subscriptions.create(
        {
          channel: 'AppVersionChannel',
        },
        {
          connected: () => {
            this.connected('appVersion', this.channels.appVersion)
          },
          disconnected: () => {
            this.disconnected('appVersion')
          },
          received: this.updateAppVersion,
        }
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
          connected: () => {
            this.connected('hangarCreate')
          },
          disconnected: () => {
            this.disconnected('hangarCreate')
          },
          received: this.addShipToHangar,
        }
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
          connected: () => {
            this.connected('hangarDestroy')
          },
          disconnected: () => {
            this.disconnected('hangarDestroy')
          },
          received: this.removeShipFromHangar,
        }
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
          connected: () => {
            this.connected('onSale')
          },
          disconnected: () => {
            this.disconnected('onSale')
          },
          received: this.notifyOnSale,
        }
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
          connected: () => {
            this.connected('onSaleHangar')
          },
          disconnected: () => {
            this.disconnected('onSaleHangar')
          },
          received: this.notifyVehicleOnSale,
        }
      )
    },

    setupUpdates() {
      this.setupAppVersionChannel()

      if (this.isAuthenticated) {
        this.setupOnSaleVehiclesChannel()
        this.setupOnSaleChannel()
        this.setupHangarCreateChannel()
        this.setupHangarDestroyChannel()
      }
    },

    unsubscribeChannel(channel) {
      this.channels[channel].unsubscribe()
      delete this.channels[channel]
    },

    updateAppVersion(data) {
      this.$store.dispatch('app/updateVersion', JSON.parse(data))
    },
  },

  mixins: [I18n],

  mounted() {
    this.setupUpdates()
    this.fetchHangarItems()
  },

  watch: {
    $route() {
      this.fetchHangarItems()
    },

    isAuthenticated() {
      this.disconnectUpdates()
      this.setupUpdates()
      this.fetchHangarItems()
    },
  },
}
