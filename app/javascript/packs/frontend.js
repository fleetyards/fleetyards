import 'stylesheets/frontend'
import Vue from 'vue'
import VTooltip from 'v-tooltip'
import VueClipboard from 'vue-clipboard2'
import App from 'frontend/App'
import router from 'frontend/lib/Router'
import store from 'frontend/lib/Store'
import 'frontend/lib/LazyLoad'
import 'frontend/lib/Sentry'
import 'frontend/lib/Bootstrap'
import I18nPlugin from 'frontend/lib/I18n'
import ApiClient from 'frontend/lib/ApiClient'
import Subscriptions from 'frontend/lib/Subscriptions'
import VueScrollTo from 'vue-scrollto'
import Comlink from 'frontend/lib/Comlink'
import Meta from 'vue-meta'
import DataPrefetch from 'frontend/lib/DataPrefetch'
import Helpers from 'frontend/lib/Helpers'
import Noty from 'frontend/lib/Noty'
import Ahoy from 'frontend/lib/Ahoy'
import Validations from 'frontend/lib/Validations'

console.info(`

███████████  ██                             ██     ██      ██                                ██                                          ██
██           ██                             ██      ██    ██                                 ██                                          ██
██           ██     ██████████  ██████████  █████    ██  ██    ██████████  ████████  ██████████  ██████████      ██████████  ██████████  █████
████████     ██     ██      ██  ██      ██  ██        ████             ██  ██        ██      ██  ██              ██      ██  ██      ██  ██
██           ██     ██████████  ██████████  ██         ██      ██████████  ██        ██      ██  ██████████      ██      ██  ██████████  ██
██           ██     ██          ██          ██         ██      ██      ██  ██        ██      ██          ██      ██      ██  ██          ██
██           ████   ██████████  ██████████  █████      ██      ██████████  ██        ██████████  ██████████  ██  ██      ██  ██████████  █████

API: https://api.fleetyards.net
GITHUB: https://github.com/fleetyards
TWITTER: https://twitter.com/FleetYardsNet

`)

Vue.use(Subscriptions)
Vue.use(ApiClient)
Vue.use(Comlink)
Vue.use(I18nPlugin)
Vue.use(DataPrefetch)
Vue.use(Helpers)
Vue.use(Noty)
Vue.use(Ahoy)
Vue.use(Validations)

Vue.use(VueClipboard)

Vue.use(VueScrollTo, {
  easing: 'ease-in-out',
  duration: 1000,
  offset: -100,
})

Vue.use(Meta, {
  keyName: 'head',
  attribute: 'data-vue-meta',
  ssrAttribute: 'data-vue-meta-server-rendered',
  tagIDKeyName: 'vmid',
})

if (process.env.NODE_ENV !== 'production') {
  Vue.config.devtools = true
} else {
  Vue.config.productionTip = false
}

VTooltip.enabled = window.innerWidth > 768
Vue.use(VTooltip)

// declare global {
//   interface Window {
//     APP_VERSION: string;
//     STORE_VERSION: string;
//     APP_CODENAME: string;
//     API_ENDPOINT: string;
//   }
// }

console.info(`APP Version: ${window.APP_VERSION} (${window.APP_CODENAME})`)
console.info(`Store Version: ${window.STORE_VERSION}`)
console.info(`API Endpoint: ${window.API_ENDPOINT}`)

document.addEventListener('DOMContentLoaded', () => {
  if ('serviceWorker' in navigator) {
    // eslint-disable-next-line compat/compat
    navigator.serviceWorker.register('/service-worker.js').then(
      registration => {
        // Registration was successful
        console.info(
          'ServiceWorker registration successful with scope: ',
          registration.scope,
        )
      },
      err => {
        // registration failed :(
        console.error('ServiceWorker registration failed: ', err)
      },
    )
  }

  if (store.state.storeVersion !== window.STORE_VERSION) {
    console.info('Updating Store Version and resetting Store')

    store.dispatch('reset')
    store.commit('setStoreVersion', window.STORE_VERSION)
  }

  store.dispatch('sentry/reset')

  // eslint-disable-next-line no-new
  new Vue({
    el: '#app',
    router,
    store,
    render: h => h(App),
  })
})
