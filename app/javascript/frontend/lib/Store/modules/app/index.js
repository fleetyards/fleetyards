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

    gitRevision(state) {
      return state.gitRevision
    },

    isUpdateAvailable(state) {
      return state.version !== window.APP_VERSION
    },

    navCollapsed(state) {
      return state.navCollapsed
    },

    navSlim(state) {
      return state.navSlim
    },

    overlayVisible(state) {
      return state.overlayVisible
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

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

    toggleSlimNav(state) {
      state.navSlim = !state.navSlim
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
