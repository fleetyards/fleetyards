import { format, parseISO, differenceInMinutes, subMinutes } from 'date-fns'
import { I18n } from 'frontend/lib/I18n'

const getLeeway = expiresAt => {
  const leewayAmount = differenceInMinutes(expiresAt, new Date()) / 3
  return subMinutes(expiresAt, Math.max(leewayAmount, 10))
}

export default {
  reset({ commit }) {
    commit('reset')
  },

  login({ commit }, payload) {
    commit('setAuthToken', payload.token)
    const renewAt = getLeeway(parseISO(payload.expires))
    commit(
      'setAuthTokenRenewAt',
      format(renewAt, I18n.t('datetime.formats.iso')),
    )
  },

  async logout({ commit }) {
    commit('setAuthTokenRenewAt', null)
    commit('setAuthToken', null)
    commit('hangar/setShips', [], { root: true })
    commit('setCurrentUser', null)
  },

  hideCookiesInfo({ commit }) {
    commit('setCookiesInfoVisible', false)
  },

  updateCookies({ commit }, payload) {
    commit('setCookies', payload)
  },
}
