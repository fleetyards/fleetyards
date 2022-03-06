import actions from './actions'
import getDefaultState from './state'

export default () => ({
  actions,

  getters: {
    fleetchartLabels(state) {
      return state.fleetchartLabels
    },

    fleetchartMode(state) {
      return state.fleetchartMode
    },

    fleetchartScale(state) {
      return state.fleetchartScale
    },

    fleetchartScreenHeight(state) {
      return state.fleetchartScreenHeight
    },

    fleetchartViewpoint(state) {
      return state.fleetchartViewpoint
    },

    fleetchartVisible(state) {
      return state.fleetchartVisible
    },

    fleetchartZoomData(state) {
      return state.fleetchartZoomData
    },

    perPage(state) {
      return state.perPage
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    setFleetchartLabels(state, payload) {
      state.fleetchartLabels = payload
    },

    setFleetchartMode(state, payload) {
      state.fleetchartMode = payload
    },

    setFleetchartScale(state, payload) {
      state.fleetchartScale = payload
    },

    setFleetchartScreenHeight(state, payload) {
      state.fleetchartScreenHeight = payload
    },

    setFleetchartViewpoint(state, payload) {
      state.fleetchartViewpoint = payload
    },

    setFleetchartVisible(state, payload) {
      state.fleetchartVisible = payload
    },

    setFleetchartZoomData(state, payload) {
      state.fleetchartZoomData = payload
    },

    setPerPage(state, payload) {
      state.perPage = payload
    },
  },

  namespaced: true,

  state: getDefaultState(),
  /* eslint-enable no-param-reassign */
})
