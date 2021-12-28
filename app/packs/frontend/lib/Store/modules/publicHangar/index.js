import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    fleetchartVisible(state) {
      return state.fleetchartVisible
    },

    fleetchartZoomData(state) {
      return state.fleetchartZoomData
    },

    fleetchartViewpoint(state) {
      return state.fleetchartViewpoint
    },

    fleetchartLabels(state) {
      return state.fleetchartLabels
    },

    fleetchartScreenHeight(state) {
      return state.fleetchartScreenHeight
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    setFleetchartVisible(state, payload) {
      state.fleetchartVisible = payload
    },

    setFleetchartZoomData(state, payload) {
      state.fleetchartZoomData = payload
    },

    setFleetchartViewpoint(state, payload) {
      state.fleetchartViewpoint = payload
    },

    setFleetchartLabels(state, payload) {
      state.fleetchartLabels = payload
    },

    setFleetchartScreenHeight(state, payload) {
      state.fleetchartScreenHeight = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
