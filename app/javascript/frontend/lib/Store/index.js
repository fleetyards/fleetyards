import Vue from 'vue'
import Vuex from 'vuex'
import actions from './actions'
import getDefaultState from './state'
import getStorePlugins from './plugins'
import getStoreModules from './modules'

Vue.use(Vuex)

const store = new Vuex.Store({
  // strict: true,

  state: getDefaultState(),

  modules: getStoreModules(),

  getters: {
    mobile(state) {
      return state.mobile
    },

    online(state) {
      return state.online
    },

    backRoutes(state) {
      return state.backRoutes
    },

    backgroundImage(state) {
      return state.backgroundImage
    },

    filters(state) {
      return state.filters
    },

    filtersVisible(state) {
      return state.filtersVisible
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

    setFilters(state, payload) {
      state.filters = { ...state.filters, ...payload }
    },

    setFiltersVisible(state, payload) {
      state.filtersVisible = { ...state.filtersVisible, ...payload }
    },
  },
  /* eslint-enable no-param-reassign */

  plugins: getStorePlugins(),
})

export default store
