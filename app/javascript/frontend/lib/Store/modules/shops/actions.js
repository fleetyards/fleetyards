import getDefaultState from './state'

export default {
  reset({ state }) {
    Object.assign(state, getDefaultState())
  },

  toggleFilter({ commit, state }) {
    commit('setFilterVisible', !state.filterVisible)
  },
}
