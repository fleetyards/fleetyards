export default {
  hideInfo({ commit }) {
    commit('setInfoVisible', false)
  },

  reset({ commit }) {
    commit('reset')
  },

  updateAcceptedCookies({ commit }, payload) {
    commit('setCookies', payload)
  },
}
