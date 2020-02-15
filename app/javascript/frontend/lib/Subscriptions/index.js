import { createConsumer } from '@rails/actioncable'
import Store from 'frontend/lib/Store'

const setupConsumer = function setupConsumer() {
  console.info('Subscriptions: Setup consumer on:', window.CABLE_ENDPOINT)

  const endpoint = `${window.CABLE_ENDPOINT}/?token=${Store.getters['session/authToken']}`

  return createConsumer(endpoint)
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
