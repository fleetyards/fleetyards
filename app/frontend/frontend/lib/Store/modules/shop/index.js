import actions from './actions'
import getDefaultState from './state'

export default () => ({
  actions,

  getters: {
    filterVisible(state) {
      return state.filterVisible
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setFilterVisible(state, payload) {
      state.filterVisible = payload
    },
  },

  namespaced: true,

  state: getDefaultState(),
  /* eslint-enable no-param-reassign */
})
