import Vue from 'vue'
import Vuex from 'vuex'
import getStorePlugins from './plugins'

Vue.use(Vuex)

// eslint-disable-next-line no-undef
const config = fleetyards_config()

const initialState = {
  locale: 'en-US',
  details: config.details || true,
  fleetchart: config.fleetchart || false,
  scale: 100,
  grouping: config.grouped || true,
  fleetchartGrouping: config.fleetchartGrouped || false,
}

const store = new Vuex.Store({
  state: initialState,
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
    scale(state) {
      return state.scale
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
    setScale(state, payload) {
      state.scale = payload
    },
  },
  /* eslint-enable no-param-reassign */
  plugins: getStorePlugins(),
})

export default store
