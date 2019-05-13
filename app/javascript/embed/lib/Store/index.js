import Vue from 'vue'
import Vuex from 'vuex'
import getStorePlugins from './plugins'
import getDefaultState from './state'
import actions from './actions'

Vue.use(Vuex)

const store = new Vuex.Store({
  state: getDefaultState(),

  actions,

  getters: {
    fleetchart(state) {
      return state.fleetchart
    },
    details(state) {
      return state.details
    },
    grouping(state) {
      return state.grouping
    },
    fleetchartScale(state) {
      return state.fleetchartScale
    },
    fleetchartGrouping(state) {
      return state.fleetchartGrouping
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    setLocale(state, locale) {
      state.locale = locale
    },
    toggleDetails(state) {
      state.details = !state.details
    },
    setDetails(state, payload) {
      state.details = payload
    },
    toggleFleetchart(state) {
      state.fleetchart = !state.fleetchart
    },
    setFleetchart(state, payload) {
      state.fleetchart = payload
    },
    toggleGrouping(state) {
      state.grouping = !state.grouping
    },
    setGrouping(state, payload) {
      state.grouping = payload
    },
    toggleFleetchartGrouping(state) {
      state.fleetchartGrouping = !state.fleetchartGrouping
    },
    setFleetchartGrouping(state, payload) {
      state.fleetchartGrouping = payload
    },
    setFleetchartScale(state, payload) {
      state.fleetchartScale = payload
    },
  },
  /* eslint-enable no-param-reassign */

  plugins: getStorePlugins(),
})

export default store
