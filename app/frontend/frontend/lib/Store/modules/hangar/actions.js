export default {
  add({ commit, state }, payload) {
    commit('add', payload)

    if (state.starterGuideVisible) {
      commit('setStarterGuideVisible', false)
    }
  },

  enableStarterGuide({ commit }) {
    commit('setStarterGuideVisible', true)
  },

  hidePreview({ commit }) {
    commit('setPreview', false)
  },

  remove({ commit }, payload) {
    commit('remove', payload)
  },

  reset({ commit }) {
    commit('reset')
  },

  saveHangar({ commit, state }, payload) {
    commit('setShips', payload)

    if (payload.length > 0 && state.starterGuideVisible) {
      commit('setStarterGuideVisible', false)
    }
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

  toggleGridView({ commit, state }) {
    commit('setGridView', !state.gridView)
  },

  toggleMoney({ commit, state }) {
    commit('setMoney', !state.money)
  },

  toggleTableSlim({ commit, state }) {
    commit('setTableSlim', !state.tableSlim)
  },

  updatePerPage({ commit }, payload) {
    commit('setPerPage', payload)
  },
}
