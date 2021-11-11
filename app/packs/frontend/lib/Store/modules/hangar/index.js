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

    fleetchartScale(state) {
      return state.fleetchartScale
    },

    fleetchartViewpoint(state) {
      return state.fleetchartViewpoint
    },

    fleetchartLabels(state) {
      return state.fleetchartLabels
    },

    publicFleetchartVisible(state) {
      return state.publicFleetchartVisible
    },

    publicFleetchartScale(state) {
      return state.publicFleetchartScale
    },

    publicFleetchartViewpoint(state) {
      return state.publicFleetchartViewpoint
    },

    publicFleetchartLabels(state) {
      return state.publicFleetchartLabels
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

    setFleetchartScale(state, payload) {
      state.fleetchartScale = payload
    },

    setFleetchartViewpoint(state, payload) {
      state.fleetchartViewpoint = payload
    },

    setFleetchartLabels(state, payload) {
      state.fleetchartLabels = payload
    },

    setPublicFleetchartVisible(state, payload) {
      state.publicFleetchartVisible = payload
    },

    setPublicFleetchartScale(state, payload) {
      state.publicFleetchartScale = payload
    },

    setPublicFleetchartViewpoint(state, payload) {
      state.publicFleetchartViewpoint = payload
    },

    setPublicFleetchartLabels(state, payload) {
      state.publicFleetchartLabels = payload
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
