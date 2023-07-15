import actions from "./actions";
import getDefaultState from "./state";

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    filterVisible(state) {
      return state.filterVisible;
    },

    perPage(state) {
      return state.perPage;
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState());
    },

    setFilterVisible(state, payload) {
      state.filterVisible = payload;
    },

    setPerPage(state, payload) {
      state.perPage = payload;
    },
  },
  /* eslint-enable no-param-reassign */
});
