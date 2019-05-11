import '@babel/polyfill'
import Vue from 'vue'
import App from 'admin/App'
import ActionCable from 'actioncable'
import { apiClient } from 'admin/lib/ApiClient'
import 'frontend/lib/LazyLoad'
import 'frontend/lib/Sentry'
import BootstrapVue from 'bootstrap-vue'
import Comlink from 'frontend/lib/Comlink'

Vue.prototype.$api = apiClient
Vue.prototype.$cable = ActionCable.createConsumer(window.CABLE_ENDPOINT)

Vue.use(Comlink)

Vue.filter('formatSize', (size) => {
  if (size > 1024 * 1024 * 1024 * 1024) {
    return `${(size / 1024 / 1024 / 1024 / 1024).toFixed(2)} TB`
  } if (size > 1024 * 1024 * 1024) {
    return `${(size / 1024 / 1024 / 1024).toFixed(2)} GB`
  } if (size > 1024 * 1024) {
    return `${(size / 1024 / 1024).toFixed(2)} MB`
  } if (size > 1024) {
    return `${(size / 1024).toFixed(2)} KB`
  }
  return `${size.toString()} B`
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

console.info(`API Endpoint: ${window.API_ENDPOINT}`)

document.addEventListener('DOMContentLoaded', () => {
  if ('serviceWorker' in navigator) {
    // eslint-disable-next-line compat/compat
    navigator.serviceWorker.getRegistrations().then((registrations) => {
      registrations.forEach(registration => registration.unregister())
    })
  }

  // eslint-disable-next-line no-new
  new Vue({
    el: '#app',
    render: h => h(App),
  })
})
