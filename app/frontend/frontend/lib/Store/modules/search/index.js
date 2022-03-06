import actions from './actions'
import getDefaultState from './state'

export default () => ({
  actions,

  getters: {
    history(state) {
      return state.history
    },
  },

  mutations: {
    addToHistory(state, payload) {
      // eslint-disable-next-line no-param-reassign
      state.history = state.history.filter(
        (item) => item.search !== payload.search
      )

      if (state.history.length >= 20) {
        state.history.pop()
      }

      state.history.unshift(payload)
    },

    reset(state) {
      Object.assign(state, getDefaultState())
    },
  },

  namespaced: true,

  state: getDefaultState(),
})
