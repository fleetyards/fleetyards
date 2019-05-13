import Vue from 'vue'
import Vuex from 'vuex'
import actions from './actions'
import getDefaultState from './state'
import getStorePlugins from './plugins'
import getStoreModules from './modules'

Vue.use(Vuex)

const store = new Vuex.Store({
  state: getDefaultState(),

  modules: getStoreModules(),

  getters: {
    mobile(state) {
      return state.mobile
    },

    previousRoute(state) {
      return state.previousRoute
    },

    navCollapsed(state) {
      return state.navCollapsed
    },

    overlayVisible(state) {
      return state.overlayVisible
    },
  },

  actions,

  /* eslint-disable no-param-reassign */
  mutations: {
    setStoreVersion(state, payload) {
      state.storeVersion = payload
    },

    setLocale(state, locale) {
      state.locale = locale
    },

    setMobile(state, payload) {
      state.mobile = payload
    },

    setOnlineStatus(state, payload) {
      state.online = payload
    },

    setBackgroundImage(state, payload) {
      state.backgroundImage = payload
    },

    setLastRoute(state, payload) {
      state.lastRoute = Object.assign({}, state.lastRoute, payload)
    },

    setPreviousRoute(state, payload) {
      state.previousRoute = Object.assign({}, state.previousRoute, payload)
    },

    setFilters(state, payload) {
      state.filters = Object.assign({}, state.filters, payload)
    },

    toggleNav(state) {
      state.navCollapsed = !state.navCollapsed
    },

    showOverlay(state) {
      state.overlayVisible = true
    },

    hideOverlay(state) {
      state.overlayVisible = false
    },

    openNav(state) {
      state.navCollapsed = false
    },

    closeNav(state) {
      state.navCollapsed = true
    },
  },
  /* eslint-enable no-param-reassign */

  plugins: getStorePlugins(),
})

export default store
