import 'stylesheets/embed'
import Vue from 'vue'
import VTooltip from 'v-tooltip'
import FleetyardsView from 'embed/FleetyardsView'
import store from 'embed/lib/Store'
import I18nPlugin from 'frontend/lib/I18n'
import ApiClient from 'embed/api/client'
import 'frontend/plugins/LazyLoad'

Vue.use(ApiClient)
Vue.use(I18nPlugin)

Vue.config.productionTip = false

VTooltip.enabled = window.innerWidth > 768
Vue.use(VTooltip, {
  defaultContainer: '#fleetyards-view',
})

// eslint-disable-next-line no-undef
const config = fleetyards_config()

setTimeout(() => {
  if (store.state.storeVersion !== window.STORE_VERSION) {
    console.info('Updating Store Version and resetting Store')

    store.dispatch('reset')
    store.commit('setStoreVersion', window.STORE_VERSION)
  }

  // eslint-disable-next-line no-new
  new Vue({
    el: '#fleetyards-view',
    store,
    data: {
      ships: config.ships || [],
      groupedButton: config.groupedButton || false,
      fleetchartSlider: config.fleetchartSlider || false,
      frontendEndpoint: window.FRONTEND_ENDPOINT,
    },
    render: (h) => h(FleetyardsView),
  })
}, 2000)
