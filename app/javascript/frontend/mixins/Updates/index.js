
import { mapGetters } from 'vuex'
import { I18n } from 'frontend/lib/I18n'
import { success } from 'frontend/lib/Noty'

export default {
  mixins: [I18n],
  data() {
    return {
      channels: {},
    }
  },
  computed: {
    ...mapGetters('session', [
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
    currentUser(value) {
      if (value) {
        this.setupUpdates()
      } else {
        this.disconnectUpdates()
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
        this.$cable.subscriptions.remove(this.channels.hangar)
        delete this.channels.hangar
      }
      if (this.channels.onSaleHangar) {
        this.$cable.subscriptions.remove(this.channels.onSaleHangar)
        delete this.channels.onSaleHangar
      }
      if (this.channels.onSale) {
        this.$cable.subscriptions.remove(this.channels.onSale)
        delete this.channels.onSale
      }
    },
    setupAppVersionUpdates() {
      this.channels.appVersion = this.$cable.subscriptions.create({
        channel: 'AppVersionChannel',
      }, {
        received: this.updateAppVersion,
        connected: () => { this.connected('AppVersionChannel') },
        disconnected: () => { this.disconnected('AppVersionChannel') },
      })
    },
    updateAppVersion(data) {
      this.$store.dispatch('app/updateVersion', JSON.parse(data))
    },
    setupHangarUpdates() {
      if (this.channels.hangar) {
        return
      }
      this.channels.hangar = this.$cable.subscriptions.create({
        channel: 'HangarChannel',
        username: this.currentUser.username,
      }, {
        received: this.updateHangar,
        connected: () => { this.connected('HangarChannel') },
        disconnected: () => { this.disconnected('HangarChannel') },
      })
    },
    updateHangar(data) {
      const vehicle = JSON.parse(data)
      if (vehicle.deleted) {
        this.$store.dispatch('hangar/remove', vehicle.model.slug)
      } else {
        this.$store.dispatch('hangar/add', vehicle.model.slug)
      }
    },
    setupOnSaleVehiclesUpdates() {
      if (this.channels.onSaleHangar) {
        return
      }
      this.channels.onSaleHangar = this.$cable.subscriptions.create({
        channel: 'OnSaleHangarChannel',
        username: this.currentUser.username,
      }, {
        received(data) {
          const vehicle = JSON.parse(data)
          success(I18n.t('messages.model.onSale', { model: vehicle.model.name }))
        },
        connected: () => { this.connected('OnSaleHangarChannel') },
        disconnected: () => { this.disconnected('OnSaleHangarChannel') },
      })
    },
    setupOnSaleUpdates() {
      if (this.channels.onSale) {
        return
      }
      this.channels.onSale = this.$cable.subscriptions.create({
        channel: 'OnSaleChannel',
      }, {
        received(data) {
          const model = JSON.parse(data)
          success(I18n.t('messages.model.onSale', { model: model.name }))
        },
        connected: () => { this.connected('OnSaleChannel') },
        disconnected: () => { this.disconnected('OnSaleChannel') },
      })
    },
    connected(_channel) {
      // console.info('Connected to', channel)
    },
    disconnected(_channel) {
      // console.info('Disconnected from', channel)
    },
  },
}
