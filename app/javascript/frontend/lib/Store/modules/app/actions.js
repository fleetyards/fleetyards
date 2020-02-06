export default {
  reset({ commit }) {
    commit('reset')
  },

  updateVersion({ state, commit }, payload = {}) {
    if (payload.version && state.appVersion !== payload.version) {
      commit('setVersion', payload.version)
      commit('setCodename', payload.codename)
    }
  },

  showOverlay({ commit }) {
    commit('setOverlayVisible', true)
  },

  hideOverlay({ commit }) {
    commit('setOverlayVisible', false)
  },
}
