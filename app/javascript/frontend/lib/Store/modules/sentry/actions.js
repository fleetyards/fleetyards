export default {
  reset({ commit }) {
    commit('reset')
  },

  add({ commit }, payload) {
    commit('addError', payload)
  },
}
