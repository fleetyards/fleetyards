import { apiClient } from 'frontend/lib/ApiClient'
import {
  format, parseISO, differenceInMinutes, isBefore, subMinutes,
} from 'date-fns'
import { I18n } from 'frontend/lib/I18n'

const getLeeway = (expiresAt) => {
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
    commit('setAuthTokenRenewAt', format(renewAt, I18n.t('datetime.formats.iso')))
  },

  async logout({ commit }, fromError = false) {
    if (!fromError) {
      try {
        await apiClient.destroy('sessions')
      } catch (error) {
      // console.error(error)
      }
    }
    commit('setAuthTokenRenewAt', null)
    commit('setAuthToken', null)
    commit('hangar/setShips', [], { root: true })
    commit('setCurrentUser', null)
  },

  async renew({ dispatch, state }) {
    if (state.authTokenRenewAt && isBefore(new Date(), parseISO(state.authTokenRenewAt))) {
      return
    }

    try {
      const response = await apiClient.put('sessions/renew')
      if (!response.error) {
        dispatch('login', response.data)
      }
    } catch (error) {
      // console.error(error)
    }
  },

  acceptCookies({ commit }) {
    commit('acceptCookies')
  },
}
