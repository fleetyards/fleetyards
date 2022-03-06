import actions from './actions'
import getDefaultState from './state'

export default () => ({
  actions,

  getters: {
    items(state) {
      return state.items
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    add(state, payload) {
      state.items.push(payload)
    },

    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setItems(state, payload) {
      state.items = payload
    },
  },

  namespaced: true,

  state: getDefaultState(),
  /* eslint-enable no-param-reassign */
})
