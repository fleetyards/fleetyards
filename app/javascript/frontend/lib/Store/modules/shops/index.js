import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    filterVisible(state) {
      return state.filterVisible
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    setFilterVisible(state, payload) {
      state.filterVisible = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
