import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    isAuthenticated(state) {
      return state.authToken !== null
    },
    authToken(state) {
      return state.authToken
    },
    currentUser(state) {
      return state.currentUser
    },
    citizen(state) {
      return state.citizen
    },
    cookiesAccepted(state) {
      return state.cookiesAccepted
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setAuthToken(state, payload) {
      state.authToken = payload
    },

    setAuthTokenRenewAt(state, payload) {
      state.authTokenRenewAt = payload
    },

    setCurrentUser(state, payload) {
      state.currentUser = payload
    },

    setCitizen(state, payload) {
      state.citizen = payload
    },

    acceptCookies(state) {
      state.cookiesAccepted = true
    },
  },
  /* eslint-enable no-param-reassign */
})
