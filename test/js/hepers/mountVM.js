import { mount, createLocalVue } from '@vue/test-utils'
import router from '@frontend/lib/Router'
import Vuex from 'vuex'
import store from '@frontend/lib/Store'
import VueLazyload from 'vue-lazyload'
import VTooltip from 'v-tooltip'
import '@frontend/lib/ApiClient'

export default function mountVM(Component, propsData) {
  const localVue = createLocalVue()

  localVue.use(Vuex)
  localVue.use(VueLazyload)
  localVue.use(VTooltip)

  return mount(Component, {
    store, router, localVue, propsData,
  })
}
