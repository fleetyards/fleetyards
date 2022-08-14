export default {
  reset({ commit }) {
    commit('reset')
  },

  toggleFleetchart({ commit, state }) {
    commit('setFleetchartVisible', !state.fleetchartVisible)
  },

  updatePerPage({ commit }, payload) {
    commit('setPerPage', payload)
  },
}
