import 'stylesheets/admin'
import Vue from 'vue'
import App from 'admin/App.vue'
import ApiClient from 'frontend/api/client'
import store from 'admin/lib/Store'
import 'frontend/plugins/LazyLoad'
import 'frontend/lib/Sentry'
import router from 'admin/lib/Router'
import Comlink from 'frontend/plugins/Comlink'
import I18nPlugin from 'frontend/lib/I18n'
import VTooltip from 'v-tooltip'
import Validations from 'frontend/plugins/Validations'

Vue.use(ApiClient)
Vue.use(Comlink)
Vue.use(I18nPlugin)
Vue.use(Validations)

declare global {
  interface Window {
    APP_VERSION: string
    STORE_VERSION: string
    APP_CODENAME: string
    API_ENDPOINT: string
    DATA_PREFILL: KeyValuePair
    ON_SUBDOMAIN: boolean
    FRONTEND_ENDPOINT: string
    SERVICE_WORKER_URL: string
  }
}

Vue.filter('formatSize', size => {
  if (size > 1024 * 1024 * 1024 * 1024) {
    return `${(size / 1024 / 1024 / 1024 / 1024).toFixed(2)} TB`
  }
  if (size > 1024 * 1024 * 1024) {
    return `${(size / 1024 / 1024 / 1024).toFixed(2)} GB`
  }
  if (size > 1024 * 1024) {
    return `${(size / 1024 / 1024).toFixed(2)} MB`
  }
  if (size > 1024) {
    return `${(size / 1024).toFixed(2)} KB`
  }
  return `${size.toString()} B`
})

if (process.env.NODE_ENV !== 'production') {
  Vue.config.devtools = true
} else {
  Vue.config.productionTip = false
}

// @ts-ignore
VTooltip.enabled = window.innerWidth > 768
Vue.use(VTooltip)

console.info(`API Endpoint: ${window.API_ENDPOINT}`)

document.addEventListener('DOMContentLoaded', () => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#app',
    router,
    store,
    render: h => h(App),
  })
})
