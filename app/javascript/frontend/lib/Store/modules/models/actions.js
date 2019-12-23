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

  toggleFleetchart({ commit, state }) {
    commit('setFleetchartVisible', !state.fleetchartVisible)
  },

  toggleHoloviewer({ commit, state }) {
    commit('setHoloviewerVisible', !state.holoviewerVisible)
  },

  enableHoloviewer({ commit }) {
    commit('setHoloviewerVisible', true)
  },
}
