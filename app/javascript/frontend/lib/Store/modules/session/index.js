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

    cookiesInfoVisible(state) {
      return state.cookiesInfoVisible
    },

    cookies(state) {
      return state.cookies
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

    setCookiesInfoVisible(state, payload) {
      state.cookiesInfoVisible = payload
    },

    setCookies(state, payload) {
      state.cookies = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
