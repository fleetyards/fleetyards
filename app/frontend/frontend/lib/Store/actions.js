export default {
  reset({ dispatch, commit }, hard = false) {
    commit('reset')
    dispatch('app/reset')

    if (hard) {
      dispatch('session/reset')
      dispatch('cookies/reset')
    }

    dispatch('fleet/reset')
    dispatch('publicFleet/reset')
    dispatch('hangar/reset')
    dispatch('publicHangar/reset')
    dispatch('models/reset')
    dispatch('search/reset')
    dispatch('shop/reset')
    dispatch('shoppingCart/reset')
    dispatch('shops/reset')
    dispatch('stations/reset')
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
