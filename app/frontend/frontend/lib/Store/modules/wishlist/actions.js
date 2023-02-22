export default {
  reset({ commit }) {
    commit("reset");
  },

  saveHangar({ commit }, payload) {
    commit("setShips", payload);
  },

  add({ commit }, payload) {
    commit("add", payload);
  },

  remove({ commit }, payload) {
    commit("remove", payload);
  },

  toggleDetails({ commit, state }) {
    commit("setDetailsVisible", !state.detailsVisible);
  },

  toggleFilter({ commit, state }) {
    commit("setFilterVisible", !state.filterVisible);
  },

  updatePerPage({ commit }, payload) {
    commit("setPerPage", payload);
  },

  toggleGridView({ commit, state }) {
    commit("setGridView", !state.gridView);
  },
};
