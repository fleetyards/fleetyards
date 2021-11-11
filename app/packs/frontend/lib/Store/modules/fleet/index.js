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

    fleetchartViewpoint(state) {
      return state.fleetchartViewpoint
    },

    fleetchartLabels(state) {
      return state.fleetchartLabels
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

    grouped(state) {
      return state.grouped
    },

    money(state) {
      return state.money
    },

    preview(state) {
      return state.preview
    },

    inviteToken(state) {
      return state.inviteToken
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

    setFleetchartViewpoint(state, payload) {
      state.fleetchartViewpoint = payload
    },

    setFleetchartLabels(state, payload) {
      state.fleetchartLabels = payload
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

    setGrouped(state, payload) {
      state.grouped = payload
    },

    setMoney(state, payload) {
      state.money = payload
    },

    setPreview(state, payload) {
      state.preview = !!payload
    },

    setInviteToken(state, payload) {
      state.inviteToken = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
