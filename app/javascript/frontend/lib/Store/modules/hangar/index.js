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

    publicFleetchartVisible(state) {
      return state.publicFleetchartVisible
    },

    publicFleetchartScale(state) {
      return state.publicFleetchartScale
    },

    money(state) {
      return state.money
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

    setPublicFleetchartVisible(state, payload) {
      state.publicFleetchartVisible = payload
    },

    setPublicFleetchartScale(state, payload) {
      state.publicFleetchartScale = payload
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
  },
  /* eslint-enable no-param-reassign */
})
