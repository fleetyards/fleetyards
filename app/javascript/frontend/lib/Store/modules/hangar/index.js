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
  },

  /* eslint-disable no-param-reassign */
  mutations: {
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
  },
  /* eslint-enable no-param-reassign */
})
