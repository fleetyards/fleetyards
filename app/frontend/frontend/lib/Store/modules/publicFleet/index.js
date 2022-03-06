import actions from './actions'
import getDefaultState from './state'

export default () => ({
  actions,

  getters: {
    detailsVisible(state) {
      return state.detailsVisible
    },

    filterVisible(state) {
      return state.filterVisible
    },

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

    grouped(state) {
      return state.grouped
    },

    inviteToken(state) {
      return state.inviteToken
    },

    money(state) {
      return state.money
    },

    perPage(state) {
      return state.perPage
    },

    preview(state) {
      return state.preview
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

    setFilterVisible(state, payload) {
      state.filterVisible = payload
    },

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

    setGrouped(state, payload) {
      state.grouped = payload
    },

    setPerPage(state, payload) {
      state.perPage = payload
    },
  },

  namespaced: true,

  state: getDefaultState(),
  /* eslint-enable no-param-reassign */
})
