export default {
  reset({ dispatch, commit }, hard = false) {
    commit('reset')
    dispatch('app/reset')

    if (hard) {
      dispatch('session/reset')
    }

    dispatch('hangar/reset')
    dispatch('models/reset')
    dispatch('stations/reset')
    dispatch('shops/reset')
    dispatch('shop/reset')
    dispatch('compare/reset')
  },

  saveFilters({ commit }, key, filters) {
    commit('setFilters', {
      [key]: filters,
    })
  },

  toggleFilterVisible({ commit, state }, key) {
    commit('setFiltersVisible', {
      [key]: !state.filtersVisible[key],
    })
  },
}
