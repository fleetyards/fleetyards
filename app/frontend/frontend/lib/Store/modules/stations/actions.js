export default {
  reset({ commit }) {
    commit("reset");
  },

  toggleFilter({ commit, state }) {
    commit("setFilterVisible", !state.filterVisible);
  },

  updatePerPage({ commit }, payload) {
    commit("setPerPage", payload);
  },
};
