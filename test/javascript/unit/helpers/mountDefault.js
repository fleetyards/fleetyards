import router from 'frontend/lib/Router'
import Vuex from 'vuex'
import store from 'frontend/lib/Store'
import I18n from 'frontend/lib/I18n'
import Comlink from 'frontend/lib/Comlink'
import VueLazyload from 'vue-lazyload'
import VTooltip from 'v-tooltip'
import BootstrapVue from 'bootstrap-vue'
import createLocalVue from './createLocalVue'

export default (config = {}) => {
  const localVue = createLocalVue(config)

  localVue.use(I18n)
  localVue.use(Vuex)
  localVue.use(VueLazyload)
  localVue.use(VTooltip)
  localVue.use(BootstrapVue)
  localVue.use(I18n)
  localVue.use(Comlink)

  return {
    store,
    router,
    localVue,

    mocks: {},
  }
}
