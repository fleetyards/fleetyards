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

    navCollapsed(state) {
      return state.navCollapsed
    },

    overlayVisible(state) {
      return state.overlayVisible
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

    toggleNav(state) {
      state.navCollapsed = !state.navCollapsed
    },

    openNav(state) {
      state.navCollapsed = false
    },

    closeNav(state) {
      state.navCollapsed = true
    },

    showOverlay(state) {
      state.overlayVisible = true
    },

    hideOverlay(state) {
      state.overlayVisible = false
    },
  },
  /* eslint-enable no-param-reassign */
})
