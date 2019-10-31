import { apiClient } from 'frontend/lib/ApiClient'

const CHECK_VERSION_INTERVAL = 60 * 1000 // 60s

export default {
  reset({ commit }) {
    commit('reset')
  },

  async init({ commit, dispatch }) {
    await dispatch('checkVersion')
    commit('setCheckVersionIntervalHandle', setInterval(() => { dispatch('checkVersion') }, CHECK_VERSION_INTERVAL))
  },

  async fetch({ commit }) {
    const response = await apiClient.get('vehicles/hangar-items', null, true)
    if (!response.error) {
      commit('setShips', response.data)
    }
  },

  hidePreview({ commit }) {
    commit('setPreview', false)
  },

  add({ commit }, payload) {
    commit('add', payload)
  },

  remove({ commit }, payload) {
    commit('remove', payload)
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
