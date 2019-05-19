import ActionCable from 'actioncable'

export default {
  install(Vue) {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$cable = ActionCable.createConsumer(window.CABLE_ENDPOINT)
  },
}
