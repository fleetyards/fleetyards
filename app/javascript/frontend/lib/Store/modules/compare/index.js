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
  },
  /* eslint-enable no-param-reassign */
})
