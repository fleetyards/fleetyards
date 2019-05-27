import actions from './actions'
import getDefaultState from './state'

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState())
    },
  },
  /* eslint-enable no-param-reassign */
})
