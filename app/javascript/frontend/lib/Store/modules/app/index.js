import actions from './actions'

export default () => ({
  namespaced: true,

  state: {
    version: window.APP_VERSION,
    codename: window.APP_CODENAME,
  },

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
