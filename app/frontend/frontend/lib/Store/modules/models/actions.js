export default {
  enableHoloviewer({ commit }) {
    commit('setHoloviewerVisible', true)
  },

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

  toggleGridView({ commit, state }) {
    commit('setGridView', !state.gridView)
  },

  toggleHoloviewer({ commit, state }) {
    commit('setHoloviewerVisible', !state.holoviewerVisible)
  },

  toggleTableSlim({ commit, state }) {
    commit('setTableSlim', !state.tableSlim)
  },

  updatePerPage({ commit }, payload) {
    commit('setPerPage', payload)
  },
}
