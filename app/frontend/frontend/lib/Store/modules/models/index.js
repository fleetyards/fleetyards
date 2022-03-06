import actions from './actions'
import getDefaultState from './state'

export default () => ({
  actions,

  getters: {
    detailsVisible(state) {
      return state.detailsVisible
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

    gridView(state) {
      return state.gridView
    },

    holoviewerVisible(state) {
      return state.holoviewerVisible
    },

    perPage(state) {
      return state.perPage
    },

    tableSlim(state) {
      return state.tableSlim
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

    setGridView(state, payload) {
      state.gridView = payload
    },

    setHoloviewerVisible(state, payload) {
      state.holoviewerVisible = payload
    },

    setPerPage(state, payload) {
      state.perPage = payload
    },

    setTableSlim(state, payload) {
      state.tableSlim = payload
    },
  },

  namespaced: true,

  state: getDefaultState(),
  /* eslint-enable no-param-reassign */
})
