export default {
  reset({ commit }) {
    commit('reset')
  },

  saveHangar({ commit, state }, payload) {
    commit('setShips', payload)

    if (payload.length > 0 && state.starterGuideVisible) {
      commit('setStarterGuideVisible', false)
    }
  },

  hidePreview({ commit }) {
    commit('setPreview', false)
  },

  add({ commit, state }, payload) {
    commit('add', payload)

    if (state.starterGuideVisible) {
      commit('setStarterGuideVisible', false)
    }
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

  toggleMoney({ commit, state }) {
    commit('setMoney', !state.money)
  },

  enableStarterGuide({ commit }) {
    commit('setStarterGuideVisible', true)
  },

  updatePerPage({ commit }, payload) {
    commit('setPerPage', payload)
  },

  toggleGridView({ commit, state }) {
    commit('setGridView', !state.gridView)
  },

  toggleFleetchart({ commit, state }) {
    commit('setFleetchartVisible', !state.fleetchartVisible)
  },
}
