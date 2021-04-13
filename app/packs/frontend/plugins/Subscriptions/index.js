import { createConsumer } from '@rails/actioncable'

const setupConsumer = function setupConsumer() {
  console.info('Subscriptions: Setup consumer on:', window.CABLE_ENDPOINT)

  return createConsumer(window.CABLE_ENDPOINT)
}

export default {
  install(Vue) {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$cable = {
      consumer: setupConsumer(),
      refresh() {
        console.info('Subscriptions: Refresh consumer')

        Vue.prototype.$cable.consumer.disconnect()

        // eslint-disable-next-line no-param-reassign
        Vue.prototype.$cable.consumer = setupConsumer()
      },
    }
  },
}
