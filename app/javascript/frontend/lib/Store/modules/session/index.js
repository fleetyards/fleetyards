import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    isAuthenticated(state) {
      return state.authenticated
    },

    currentUser(state) {
      return state.currentUser
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setAuthenticated(state, payload) {
      state.authenticated = payload
    },

    setCurrentUser(state, payload) {
      state.currentUser = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
