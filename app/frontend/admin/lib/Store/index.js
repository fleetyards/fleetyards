import Vue from 'vue'
import Vuex from 'vuex'
import actions from './actions'
import getDefaultState from './state'
import getStoreModules from './modules'

Vue.use(Vuex)

const store = new Vuex.Store({
  actions,

  getters: {
    backRoutes(state) {
      return state.backRoutes
    },

    filters(state) {
      return state.filters
    },

    filtersVisible(state) {
      return state.filtersVisible
    },

    mobile(state) {
      return state.mobile
    },

    online(state) {
      return state.online
    },
  },

  modules: getStoreModules(),

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setFilters(state, payload) {
      state.filters = { ...state.filters, ...payload }
    },

    setFiltersVisible(state, payload) {
      state.filtersVisible = { ...state.filtersVisible, ...payload }
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

    setStoreVersion(state, payload) {
      state.storeVersion = payload
    },
  },

  // strict: true,
  state: getDefaultState(),
  /* eslint-enable no-param-reassign */
})

export default store
