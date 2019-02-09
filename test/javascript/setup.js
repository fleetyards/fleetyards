import { shallowMount, createLocalVue } from '@vue/test-utils'
import router from 'frontend/lib/Router'
import Vuex from 'vuex'
import store from 'frontend/lib/Store'
import VueLazyload from 'vue-lazyload'
import VTooltip from 'v-tooltip'
import BootstrapVue from 'bootstrap-vue'
import 'frontend/lib/ApiClient'

jest.mock('frontend/lib/Store/plugins')

global.mountVM = function mountVM(Component, propsData) {
  const localVue = createLocalVue()

  localVue.use(Vuex)
  localVue.use(VueLazyload)
  localVue.use(VTooltip)
  localVue.use(BootstrapVue)

  return shallowMount(Component, {
    store,
    router,
    localVue,
    propsData,
  })
}
