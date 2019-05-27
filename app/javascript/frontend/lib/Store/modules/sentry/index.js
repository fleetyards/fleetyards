import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {},

  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    addError(state, payload) {
      state.errors.push(payload)
    },
  },
})
