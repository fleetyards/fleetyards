import { parseISO, differenceInMinutes } from 'date-fns'
import actions from './actions'
import getDefaultState from './state'

export default () => ({
  actions,

  getters: {
    accessConfirmed(state) {
      if (!state.accessConfirmed) {
        return false
      }

      const diff = differenceInMinutes(
        new Date(),
        parseISO(state.accessConfirmed)
      )

      return diff < 10
    },

    currentUser(state) {
      return state.currentUser
    },

    isAuthenticated(state) {
      return state.authenticated
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setAccessConfirmed(state, payload) {
      state.accessConfirmed = payload
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
  },

  namespaced: true,

  state: getDefaultState(),
  /* eslint-enable no-param-reassign */
})
