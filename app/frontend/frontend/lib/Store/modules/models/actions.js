export default {
  reset({ commit }) {
    commit('reset')
  },

  toggleFilter({ commit, state }) {
    commit('setFilterVisible', !state.filterVisible)
  },

  toggleDetails({ commit, state }) {
    commit('setDetailsVisible', !state.detailsVisible)
  },

  toggleHoloviewer({ commit, state }) {
    commit('setHoloviewerVisible', !state.holoviewerVisible)
  },

  enableHoloviewer({ commit }) {
    commit('setHoloviewerVisible', true)
  },

  toggleFleetchart({ commit, state }) {
    commit('setFleetchartVisible', !state.fleetchartVisible)
  },

  updatePerPage({ commit }, payload) {
    commit('setPerPage', payload)
  },
}
