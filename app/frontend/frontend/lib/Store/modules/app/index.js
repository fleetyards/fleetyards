import actions from './actions'
import getDefaultState from './state'

export default () => ({
  actions,

  getters: {
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

    version(state) {
      return state.version
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    closeNav(state) {
      state.navCollapsed = true
    },

    openNav(state) {
      state.navCollapsed = false
    },

    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setCheckVersionIntervalHandle(state, payload) {
      state.checkVersionIntervalHandle = payload
    },

    setCodename(state, payload) {
      state.codename = payload
    },

    setNavCollapsed(state, payload) {
      state.navCollapsed = payload
    },

    setOverlayVisible(state, payload) {
      state.overlayVisible = payload
    },

    setVersion(state, payload) {
      state.version = payload
    },

    toggleSlimNav(state) {
      state.navSlim = !state.navSlim
    },
  },

  namespaced: true,

  state: getDefaultState(),
  /* eslint-enable no-param-reassign */
})
