export default {
  hidePreview({ commit }) {
    commit('setPreview', false)
  },

  reset({ commit }) {
    commit('reset')
  },

  resetInviteToken({ commit }) {
    commit('setInviteToken', null)
  },

  saveInviteToken({ commit }, payload) {
    commit('setInviteToken', payload)
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

  toggleGrouped({ commit, state }) {
    commit('setGrouped', !state.grouped)
  },

  toggleMoney({ commit, state }) {
    commit('setMoney', !state.money)
  },

  updatePerPage({ commit }, payload) {
    commit('setPerPage', payload)
  },
}
