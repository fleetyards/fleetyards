import 'stylesheets/admin'
import Vue from 'vue'
import App from 'admin/App'
import ApiClient from 'admin/lib/ApiClient'
import 'frontend/plugins/LazyLoad'
import 'frontend/lib/Sentry'
import router from 'admin/lib/Router'
import Comlink from 'frontend/plugins/Comlink'
import I18nPlugin from 'frontend/lib/I18n'

Vue.use(ApiClient)
Vue.use(Comlink)
Vue.use(I18nPlugin)

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

console.info(`API Endpoint: ${window.API_ENDPOINT}`)

document.addEventListener('DOMContentLoaded', () => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#app',
    router,
    render: h => h(App),
  })
})
