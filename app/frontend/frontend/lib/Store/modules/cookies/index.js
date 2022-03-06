import actions from './actions'
import getDefaultState from './state'

export default () => ({
  actions,

  getters: {
    cookies(state) {
      return state.cookies
    },

    infoVisible(state) {
      return state.infoVisible
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setCookies(state, payload) {
      state.cookies = payload
    },

    setInfoVisible(state, payload) {
      state.infoVisible = payload
    },
  },

  namespaced: true,

  state: getDefaultState(),
  /* eslint-enable no-param-reassign */
})
