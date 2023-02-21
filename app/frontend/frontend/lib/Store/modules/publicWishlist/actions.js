export default {
  reset({ commit }) {
    commit("reset");
  },

  updatePerPage({ commit }, payload) {
    commit("setPerPage", payload);
  },
};
