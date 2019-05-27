import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    backRoute(state) {
      return state.backRoute
    },

    filterVisible(state) {
      return state.filterVisible
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setBackRoute(state, payload) {
      state.backRoute = payload
    },

    setFilterVisible(state, payload) {
      state.filterVisible = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
