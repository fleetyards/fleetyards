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

    holoviewerVisible(state) {
      return state.holoviewerVisible
    },

    perPage(state) {
      return state.perPage
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

    setHoloviewerVisible(state, payload) {
      state.holoviewerVisible = payload
    },

    setPerPage(state, payload) {
      state.perPage = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
