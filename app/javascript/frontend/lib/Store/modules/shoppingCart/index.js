import { sortBy } from 'frontend/lib/Helpers'
import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    items(state) {
      return state.items
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },

    setItems(state, payload) {
      state.items = payload
    },

    add(state, payload) {
      const soldAt = sortBy(payload.soldAt || [], 'sellPrice')
      state.items.push({
        id: payload.id,
        type: payload.type,
        name: payload.name,
        bestSoldAt: soldAt[0],
        soldAt,
      })
    },

    remove(state, payload) {
      const index = state.items.findIndex(item => item.id === payload.id)
      state.items.splice(index, 1)
    },
  },
  /* eslint-enable no-param-reassign */
})
