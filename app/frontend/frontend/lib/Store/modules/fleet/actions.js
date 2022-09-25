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

  toggleMoney({ commit, state }) {
    commit("setMoney", !state.money);
  },

  hidePreview({ commit }) {
    commit("setPreview", false);
  },

  saveInviteToken({ commit }, payload) {
    commit("setInviteToken", payload);
  },

  resetInviteToken({ commit }) {
    commit("setInviteToken", null);
  },

  toggleFleetchart({ commit, state }) {
    commit("setFleetchartVisible", !state.fleetchartVisible);
  },

  updatePerPage({ commit }, payload) {
    commit("setPerPage", payload);
  },
};
