import Vue from 'vue'
import Vuex from 'vuex'
import getStorePlugins from './plugins'
import getDefaultState from './state'
import actions from './actions'

Vue.use(Vuex)

const store = new Vuex.Store({
  actions,

  getters: {
    details(state) {
      return state.details
    },
    fleetchart(state) {
      return state.fleetchart
    },
    fleetchartGrouping(state) {
      return state.fleetchartGrouping
    },
    fleetchartScale(state) {
      return state.fleetchartScale
    },
    grouping(state) {
      return state.grouping
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    setDetails(state, payload) {
      state.details = payload
    },
    setFleetchart(state, payload) {
      state.fleetchart = payload
    },
    setFleetchartGrouping(state, payload) {
      state.fleetchartGrouping = payload
    },
    setFleetchartScale(state, payload) {
      state.fleetchartScale = payload
    },
    setGrouping(state, payload) {
      state.grouping = payload
    },
    setLocale(state, locale) {
      state.locale = locale
    },
    setStoreVersion(state, payload) {
      state.storeVersion = payload
    },
    toggleDetails(state) {
      state.details = !state.details
    },
    toggleFleetchart(state) {
      state.fleetchart = !state.fleetchart
    },
    toggleFleetchartGrouping(state) {
      state.fleetchartGrouping = !state.fleetchartGrouping
    },
    toggleGrouping(state) {
      state.grouping = !state.grouping
    },
  },

  /* eslint-enable no-param-reassign */
  plugins: getStorePlugins(),

  state: getDefaultState(),
})

export default store
