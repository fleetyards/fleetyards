export default {
  reset({ commit }) {
    commit('reset')
  },

  save({ commit }, payload) {
    commit('addToHistory', payload)
  },
}
