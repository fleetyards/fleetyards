import 'stylesheets/main'
import 'babel-polyfill'
import Vue from 'vue'
import Raven from 'raven-js'
import RavenVue from 'raven-js/plugins/vue'
import VeeValidate, { Validator } from 'vee-validate'
import { sync } from 'vuex-router-sync'
import VTooltip from 'v-tooltip'
import VueClipboard from 'vue-clipboard2'
import App from 'frontend/App'
import router from 'frontend/lib/Router'
import store from 'frontend/lib/Store'
import ActionCable from 'actioncable'
import 'frontend/lib/ApiClient'
import 'frontend/lib/LazyLoad'
import BootstrapVue from 'bootstrap-vue'
import VueScrollTo from 'vue-scrollto'
import Comlink from 'frontend/lib/Comlink'
import EmailValidator from 'frontend/lib/validations/EmailValidator'
import UsernameValidator from 'frontend/lib/validations/UsernameValidator'
import OrgValidator from 'frontend/lib/validations/OrgValidator'
import HandleValidator from 'frontend/lib/validations/HandleValidator'
import Meta from 'vue-meta'

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

Vue.prototype.$cable = ActionCable.createConsumer(process.env.CABLE_URL)

Vue.use(Comlink)

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

Vue.use(VueClipboard)

sync(store, router)

Raven.config(process.env.RAVEN_DSN)
  .addPlugin(RavenVue, Vue)
  .install()

Vue.config.productionTip = false

VTooltip.enabled = window.innerWidth > 768
Vue.use(VTooltip)

document.addEventListener('DOMContentLoaded', () => {
  if ('serviceWorker' in navigator) {
    // eslint-disable-next-line compat/compat
    navigator.serviceWorker.register('/service-worker.js')
  }

  // eslint-disable-next-line no-new
  new Vue({
    el: '#app',
    router,
    store,
    created() {
      this.checkStoreVersion()
    },
    methods: {
      checkStoreVersion() {
        if (this.$store.state.version !== process.env.STORE_VERSION) {
          this.$store.commit('reset')
          this.$store.commit('setStoreVersion', process.env.STORE_VERSION)
        }
      },
    },
    render: h => h(App),
  })
})
