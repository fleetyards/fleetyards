import { formatISO } from 'date-fns'

export default {
  reset({ commit }) {
    commit('reset')
  },

  login({ commit }) {
    commit('setAuthenticated', true)
  },

  async logout({ commit }) {
    commit('setAuthenticated', false)
    commit('hangar/setShips', [], { root: true })
    commit('setCurrentUser', null)
  },

  hideCookiesInfo({ commit }) {
    commit('setCookiesInfoVisible', false)
  },

  updateCookies({ commit }, payload) {
    commit('setCookies', payload)
  },

  confirmAccess({ commit }) {
    commit('setAccessConfirmed', formatISO(new Date()))
  },

  resetConfirmAccess({ commit }) {
    commit('setAccessConfirmed', null)
  },
}
