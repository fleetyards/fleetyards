import { formatISO } from 'date-fns'

export default {
  confirmAccess({ commit }) {
    commit('setAccessConfirmed', formatISO(new Date()))
  },

  hideCookiesInfo({ commit }) {
    commit('setCookiesInfoVisible', false)
  },

  login({ commit }) {
    commit('setAuthenticated', true)
  },

  async logout({ commit }) {
    commit('setAuthenticated', false)
    commit('hangar/setShips', [], { root: true })
    commit('setCurrentUser', null)
  },

  reset({ commit }) {
    commit('reset')
  },

  resetConfirmAccess({ commit }) {
    commit('setAccessConfirmed', null)
  },

  updateCookies({ commit }, payload) {
    commit('setCookies', payload)
  },
}
