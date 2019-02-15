import 'stylesheets/embed'
import '@babel/polyfill'
import Vue from 'vue'
import VTooltip from 'v-tooltip'
import FleetyardsView from 'embed/FleetyardsView'
import store from 'embed/lib/Store'
import { apiClient } from 'frontend/lib/ApiClient'
import 'frontend/lib/LazyLoad'

Vue.prototype.$api = apiClient

Vue.config.productionTip = false

VTooltip.enabled = window.innerWidth > 768
Vue.use(VTooltip, {
  defaultContainer: '#fleetyards-view',
})

// eslint-disable-next-line no-undef
const config = fleetyards_config()

setTimeout(() => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#fleetyards-view',
    store,
    data: {
      ships: config.ships || [],
      groupedButton: config.groupedButton || false,
      fleetchartSlider: config.fleetchartSlider || false,
      frontendHost: process.env.FRONTEND_HOST,
    },
    render: h => h(FleetyardsView),
  })
}, 1000)
