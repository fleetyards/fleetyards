import Vue from 'vue'
import VTooltip from 'v-tooltip'
import FleetyardsView from '@/embed/FleetyardsView.vue'
import store from '@/embed/lib/Store'
import I18nPlugin from '@/frontend/lib/I18n'
import ApiClient from '@/embed/api/client'
import '@/frontend/plugins/LazyLoad'

Vue.use(ApiClient)
Vue.use(I18nPlugin)

Vue.config.productionTip = false

VTooltip.enabled = window.innerWidth > 768
Vue.use(VTooltip, {
  defaultContainer: '#fleetyards-view',
})

window.FleetYardsFleetchart = null

setTimeout(() => {
  if (store.state.storeVersion !== window.STORE_VERSION) {
    console.info('Updating Store Version and resetting Store')

    store.dispatch('reset')
    store.commit('setStoreVersion', window.STORE_VERSION)
  }

  // eslint-disable-next-line no-undef
  const config = window.FleetYardsFleetchartConfig || {}

  // eslint-disable-next-line no-new
  window.FleetYardsFleetchart = new Vue({
    el: '#fleetyards-view',
    data: {
      fleetchartSlider: config.fleetchartSlider || false,
      fleetID: config.fleetID || null,
      frontendEndpoint: window.FRONTEND_ENDPOINT,
      groupedButton: config.groupedButton || false,
      ships: config.ships || [],
      users: config.users || [],
    },

    methods: {
      updateFleet(fleetID) {
        const fleetview = (this.$children || [])[0]
        if (fleetview) {
          fleetview.updateFleet(fleetID)
        }
      },

      updateShips(ships) {
        const fleetview = (this.$children || [])[0]
        if (fleetview) {
          fleetview.updateShips(ships)
        }
      },

      updateUsers(users) {
        const fleetview = (this.$children || [])[0]
        if (fleetview) {
          fleetview.updateUsers(users)
        }
      },
    },
    render: (h) => h(FleetyardsView),
    store,
  })
}, 2000)
