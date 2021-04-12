import { parseISO, differenceInMinutes } from 'date-fns'
import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    isAuthenticated(state) {
      return state.authenticated
    },

    currentUser(state) {
      return state.currentUser
    },

    accessConfirmed(state) {
      if (!state.accessConfirmed) {
        return false
      }

      const diff = differenceInMinutes(
        new Date(),
        parseISO(state.accessConfirmed),
      )

      return diff < 10
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setAuthenticated(state, payload) {
      state.authenticated = payload
    },

    setCurrentUser(state, payload) {
      if (payload) {
        state.currentUser = payload.data
      } else {
        state.currentUser = null
      }
    },

    setAccessConfirmed(state, payload) {
      state.accessConfirmed = payload
    },
  },
  /* eslint-enable no-param-reassign */
})
