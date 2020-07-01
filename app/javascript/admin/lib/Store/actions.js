export default {
  reset({ commit }) {
    commit('reset')
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
