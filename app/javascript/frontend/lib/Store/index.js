import Vue from 'vue'
import Vuex from 'vuex'
import actions from './actions'
import getDefaultState from './state'
import getStorePlugins from './plugins'
import getStoreModules from './modules'

Vue.use(Vuex)

const store = new Vuex.Store({
  strict: true,

  state: getDefaultState(),

  modules: getStoreModules(),

  getters: {
    mobile(state) {
      return state.mobile
    },

    previousRoute(state) {
      return state.previousRoute
    },
  },

  actions,

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

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
  },
  /* eslint-enable no-param-reassign */

  plugins: getStorePlugins(),
})

export default store
