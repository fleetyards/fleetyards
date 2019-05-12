import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    version(state) {
      return state.version
    },
    codename(state) {
      return state.codename
    },
    isUpdateAvailable(state) {
      return state.version !== window.APP_VERSION
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    setCheckVersionIntervalHandle(state, payload) {
      state.checkVersionIntervalHandle = payload
    },
    setVersion(state, payload) {
      state.version = payload
    },
    setCodename(state, payload) {
      state.codename = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
