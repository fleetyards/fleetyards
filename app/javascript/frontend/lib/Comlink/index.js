export default {
  install (Vue) {
    const Bus = new Vue()

    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$comlink = Bus
  },
}
