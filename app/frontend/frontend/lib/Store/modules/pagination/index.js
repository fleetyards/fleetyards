import actions from "./actions";
import getDefaultState from "./state";

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions: {
    reset({ commit }) {
      commit("reset");
    },

    updatePerPage({ commit }, payload) {
      commit("setPerPage", payload);
    },
  },

  getters: {
    perPage(state, key) {
      return state.perPage;
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState());
    },

    setPerPage(state, payload) {
      state.perPage = payload;
    },
  },
  /* eslint-enable no-param-reassign */
});
