import 'stylesheets/main'
import '@babel/polyfill'
import Vue from 'vue'
import VeeValidate, { Validator } from 'vee-validate'
import VTooltip from 'v-tooltip'
import VueClipboard from 'vue-clipboard2'
import App from 'frontend/App'
import router from 'frontend/lib/Router'
import store from 'frontend/lib/Store'
import 'frontend/lib/LazyLoad'
import 'frontend/lib/Sentry'
import 'frontend/lib/Ahoy'
import I18n from 'frontend/lib/I18n'
import ApiClient from 'frontend/lib/ApiClient'
import Subscriptions from 'frontend/lib/Subscriptions'
import BootstrapVue from 'bootstrap-vue'
import VueScrollTo from 'vue-scrollto'
import Comlink from 'frontend/lib/Comlink'
import EmailValidator from 'frontend/lib/validations/EmailValidator'
import UsernameValidator from 'frontend/lib/validations/UsernameValidator'
import OrgValidator from 'frontend/lib/validations/OrgValidator'
import HandleValidator from 'frontend/lib/validations/HandleValidator'
import Meta from 'vue-meta'
import DataPrefetch from 'frontend/lib/DataPrefetch'
import Noty from 'frontend/lib/Noty'

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
Vue.use(I18n)
Vue.use(DataPrefetch)
Vue.use(Noty)

Vue.use(VueClipboard)

Vue.use(VeeValidate)
Validator.extend('emailTaken', EmailValidator)
Validator.extend('usernameTaken', UsernameValidator)
Validator.extend('org', OrgValidator)
Validator.extend('handle', HandleValidator)

Vue.use(VueScrollTo, {
  easing: 'ease-in-out',
  duration: 1000,
  offset: -100,
})

Vue.use(Meta, {
  keyName: 'metaInfo',
  attribute: 'data-vue-meta',
  ssrAttribute: 'data-vue-meta-server-rendered',
  tagIDKeyName: 'vmid',
})

const originalVueComponent = Vue.component
Vue.component = function bootstrapFix(name, definition) {
  if (name === 'bFormCheckboxGroup' || name === 'bCheckboxGroup'
      || name === 'bCheckGroup' || name === 'bFormRadioGroup') {
    // eslint-disable-next-line no-param-reassign
    definition.components = { bFormCheckbox: definition.components[0] }
  }
  originalVueComponent.apply(this, [name, definition])
}
Vue.use(BootstrapVue)

if (process.env.NODE_ENV !== 'production') {
  Vue.config.devtools = true
} else {
  Vue.config.productionTip = false
}

VTooltip.enabled = window.innerWidth > 768
Vue.use(VTooltip)

console.info(`APP Version: ${window.APP_VERSION} (${window.APP_CODENAME})`)
console.info(`Store Version: ${window.STORE_VERSION}`)
console.info(`API Endpoint: ${window.API_ENDPOINT}`)

document.addEventListener('DOMContentLoaded', () => {
  if ('serviceWorker' in navigator) {
    // eslint-disable-next-line compat/compat
    navigator.serviceWorker.register('/service-worker.js').then((registration) => {
      // Registration was successful
      console.info('ServiceWorker registration successful with scope: ', registration.scope)
    }, (err) => {
      // registration failed :(
      console.error('ServiceWorker registration failed: ', err)
    })
  }

  if (store.state.storeVersion !== window.STORE_VERSION) {
    console.info('Updating Store Version and resetting Store')

    store.dispatch('reset')
    store.commit('setStoreVersion', window.STORE_VERSION)
  }

  store.dispatch('sentry/reset')

  store.dispatch('app/init')

  // eslint-disable-next-line no-new
  new Vue({
    el: '#app',
    router,
    store,
    render: h => h(App),
  })
})
