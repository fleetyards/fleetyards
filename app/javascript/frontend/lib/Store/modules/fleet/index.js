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

    filterVisible(state) {
      return state.filterVisible
    },

    fleetchartVisible(state) {
      return state.fleetchartVisible
    },

    fleetchartScale(state) {
      return state.fleetchartScale
    },

    grouped(state) {
      return state.grouped
    },

    money(state) {
      return state.money
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

    setFleetchartVisible(state, payload) {
      state.fleetchartVisible = payload
    },

    setFleetchartScale(state, payload) {
      state.fleetchartScale = payload
    },

    setGrouped(state, payload) {
      state.grouped = payload
    },

    setMoney(state, payload) {
      state.money = payload
    },

    setPreview(state, payload) {
      state.preview = !!payload
    },
  },
  /* eslint-enable no-param-reassign */
})
