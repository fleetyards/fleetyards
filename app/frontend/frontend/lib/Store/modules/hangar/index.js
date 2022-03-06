import actions from './actions'
import getDefaultState from './state'

export default () => ({
  actions,

  getters: {
    detailsVisible(state) {
      return state.detailsVisible
    },

    empty(state) {
      return state.ships.length === 0
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

    gridView(state) {
      return state.gridView
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

    ships(state) {
      return state.ships
    },

    starterGuideVisible(state) {
      return state.starterGuideVisible
    },

    tableSlim(state) {
      return state.tableSlim
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    add(state, payload) {
      state.ships.push(payload)
    },

    remove(state, payload) {
      state.ships.splice(state.ships.indexOf(payload), 1)
    },

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

    setGridView(state, payload) {
      state.gridView = payload
    },

    setMoney(state, payload) {
      state.money = payload
    },

    setPerPage(state, payload) {
      state.perPage = payload
    },

    setPreview(state, payload) {
      state.preview = !!payload
    },

    setShips(state, payload) {
      state.ships = payload
    },

    setStarterGuideVisible(state, payload) {
      state.starterGuideVisible = payload
    },

    setTableSlim(state, payload) {
      state.tableSlim = payload
    },
  },

  namespaced: true,

  state: getDefaultState(),
  /* eslint-enable no-param-reassign */
})
