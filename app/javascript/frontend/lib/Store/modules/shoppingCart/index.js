import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    items(state) {
      return state.items
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setItems(state, payload) {
      state.items = payload
    },

    add(state, payload) {
      state.items.push(payload)
    },
  },
  /* eslint-enable no-param-reassign */
})
