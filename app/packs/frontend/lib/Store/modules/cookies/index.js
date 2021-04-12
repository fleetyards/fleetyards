import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    infoVisible(state) {
      return state.infoVisible
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

    setInfoVisible(state, payload) {
      state.infoVisible = payload
    },

    setCookies(state, payload) {
      state.cookies = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
