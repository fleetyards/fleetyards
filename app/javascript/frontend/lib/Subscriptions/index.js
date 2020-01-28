import { createConsumer } from '@rails/actioncable'

export default {
  install(Vue) {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$cable = createConsumer(window.CABLE_ENDPOINT)
  },
}
