import { apiClient } from 'frontend/lib/ApiClient'
import getDefaultState from './state'

const CHECK_VERSION_INTERVAL = 60 * 1000 // 60s

export default {
  reset({ state }) {
    Object.assign(state, getDefaultState())
  },

  async init({ commit, dispatch }) {
    await dispatch('checkVersion')
    commit('setCheckVersionIntervalHandle', setInterval(() => { dispatch('checkVersion') }, CHECK_VERSION_INTERVAL))
  },

  async fetch({ commit }) {
    const response = await apiClient.get('vehicles/hangar-items')
    if (!response.error) {
      commit('setShips', response.data)
    }
  },

  add({ state }, payload) {
    state.ships.push(payload)
  },

  remove({ state }, payload) {
    state.ships.splice(state.ships.indexOf(payload), 1)
  },

  toggleDetails({ commit, state }) {
    commit('setDetailsVisible', !state.detailsVisible)
  },

  toggleFilter({ commit, state }) {
    commit('setFilterVisible', !state.filterVisible)
  },

  toggleFleetchart({ commit, state }) {
    commit('setFleetchartVisible', !state.fleetchartVisible)
  },

  togglePublicFleetchart({ commit, state }) {
    commit('setPublicFleetchartVisible', !state.publicFleetchartVisible)
  },
}
