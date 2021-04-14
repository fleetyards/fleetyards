export default {
  reset({ commit }) {
    commit('reset')
  },

  hideInfo({ commit }) {
    commit('setInfoVisible', false)
  },

  updateAcceptedCookies({ commit }, payload) {
    commit('setCookies', payload)
  },
}
