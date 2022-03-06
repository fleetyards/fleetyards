export default {
  hideOverlay({ commit }) {
    commit('setOverlayVisible', false)
  },

  reset({ commit }) {
    commit('reset')
  },

  showOverlay({ commit }) {
    commit('setOverlayVisible', true)
  },

  toggleNav({ state, commit }) {
    commit('setNavCollapsed', !state.navCollapsed)
  },

  updateVersion({ state, commit }, payload = {}) {
    if (payload && payload.version && state.appVersion !== payload.version) {
      commit('setVersion', payload.version)
      commit('setCodename', payload.codename)
    }
  },
}
