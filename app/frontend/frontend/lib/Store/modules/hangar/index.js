import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    ships(state) {
      return state.ships
    },

    preview(state) {
      return state.preview
    },

    empty(state) {
      return state.ships.length === 0
    },

    detailsVisible(state) {
      return state.detailsVisible
    },

    filterVisible(state) {
      return state.filterVisible
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

    fleetchartMode(state) {
      return state.fleetchartMode
    },

    fleetchartScale(state) {
      return state.fleetchartScale
    },

    money(state) {
      return state.money
    },

    starterGuideVisible(state) {
      return state.starterGuideVisible
    },

    perPage(state) {
      return state.perPage
    },

    gridView(state) {
      return state.gridView
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    add(state, payload) {
      state.ships.push(payload)
    },

    remove(state, payload) {
      state.ships.splice(state.ships.indexOf(payload), 1)
    },

    setDetailsVisible(state, payload) {
      state.detailsVisible = payload
    },

    setFilterVisible(state, payload) {
      state.filterVisible = payload
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

    setFleetchartMode(state, payload) {
      state.fleetchartMode = payload
    },

    setFleetchartScale(state, payload) {
      state.fleetchartScale = payload
    },

    setShips(state, payload) {
      state.ships = payload
    },

    setPreview(state, payload) {
      state.preview = !!payload
    },

    setMoney(state, payload) {
      state.money = payload
    },

    setStarterGuideVisible(state, payload) {
      state.starterGuideVisible = payload
    },

    setPerPage(state, payload) {
      state.perPage = payload
    },

    setGridView(state, payload) {
      state.gridView = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
