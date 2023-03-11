export default {
  reset({ commit }) {
    commit("reset");
  },

  toggleDetails({ commit, state }) {
    commit("setDetailsVisible", !state.detailsVisible);
  },

  toggleFilter({ commit, state }) {
    commit("setFilterVisible", !state.filterVisible);
  },

  toggleGrouped({ commit, state }) {
    commit("setGrouped", !state.grouped);
  },

  toggleFleetchart({ commit, state }) {
    commit("setFleetchartVisible", !state.fleetchartVisible);
  },

  toggleColored({ commit, state }) {
    commit("setFleetchartColored", !state.fleetchartColored);
  },

  updatePerPage({ commit }, payload) {
    commit("setPerPage", payload);
  },
};
