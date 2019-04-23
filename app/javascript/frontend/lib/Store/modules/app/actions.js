import { apiClient } from 'frontend/lib/ApiClient'
import getDefaultState from './state'

const CHECK_VERSION_INTERVAL = 60 * 1000 // 60s

export default {
  reset({ state }) {
    Object.assign(state, getDefaultState())
  },

  async init({ commit, dispatch }) {
    await dispatch('checkVersion')
    commit('setCheckVersionIntervalHandle', setInterval(() => { dispatch('checkVersion') }, CHECK_VERSION_INTERVAL))
  },

  async checkVersion({ dispatch }) {
    const response = await apiClient.get('version')
    if (!response.error) {
      dispatch('updateVersion', response.data)
    }
  },

  updateVersion({ state, commit }, payload = {}) {
    if (payload.version && state.appVersion !== payload.version) {
      commit('setVersion', payload.version)
      commit('setCodename', payload.codename)
    }
  },
}
