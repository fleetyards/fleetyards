import { apiClient } from 'frontend/lib/ApiClient'

export default {
  reset({ commit }) {
    commit('reset')
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

  toggleMoney({ commit, state }) {
    commit('setMoney', !state.money)
  },
}
