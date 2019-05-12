import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    prices(state) {
      return state.prices
    },

    pricesID(state) {
      return state.pricesID
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    setPrices(state, payload) {
      state.prices = payload
    },

    setPricesID(state, payload) {
      state.pricesID = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
