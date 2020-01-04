import 'stylesheets/embed-v2'
import Vue from 'vue'
import VTooltip from 'v-tooltip'
import FleetyardsView from 'embed/FleetyardsView'
import store from 'embed/lib/Store'
import ApiClient from 'frontend/lib/ApiClient'
import I18n from 'frontend/lib/I18n'
import Noty from 'frontend/lib/Noty'
import 'frontend/lib/LazyLoad'
import 'frontend/lib/Bootstrap'

Vue.use(ApiClient)
Vue.use(I18n)
Vue.use(Noty)

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
    store,
    data: {
      ships: config.ships || [],
      users: config.users || [],
      groupedButton: config.groupedButton || false,
      fleetchartSlider: config.fleetchartSlider || false,
      frontendEndpoint: window.FRONTEND_ENDPOINT,
    },
    methods: {
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
  })
}, 2000)
