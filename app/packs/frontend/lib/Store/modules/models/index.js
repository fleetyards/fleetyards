import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    detailsVisible(state) {
      return state.detailsVisible
    },

    fleetchartVisible(state) {
      return state.fleetchartVisible
    },

    fleetchartScale(state) {
      return state.fleetchartScale
    },

    fleetchartViewpoint(state) {
      return state.fleetchartViewpoint
    },

    fleetchartLabels(state) {
      return state.fleetchartLabels
    },

    holoviewerVisible(state) {
      return state.holoviewerVisible
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setDetailsVisible(state, payload) {
      state.detailsVisible = payload
    },

    setFleetchartVisible(state, payload) {
      state.fleetchartVisible = payload
    },

    setFleetchartScale(state, payload) {
      state.fleetchartScale = payload
    },

    setFleetchartViewpoint(state, payload) {
      state.fleetchartViewpoint = payload
    },

    setFleetchartLabels(state, payload) {
      state.fleetchartLabels = payload
    },

    setHoloviewerVisible(state, payload) {
      state.holoviewerVisible = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
