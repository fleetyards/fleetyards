export default {
  reset({ commit }) {
    commit('reset')
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

  hidePreview({ commit }) {
    commit('setPreview', false)
  },
}
