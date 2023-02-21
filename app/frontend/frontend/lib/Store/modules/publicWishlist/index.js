import actions from "./actions";
import getDefaultState from "./state";

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    perPage(state) {
      return state.perPage;
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    setPerPage(state, payload) {
      state.perPage = payload;
    },
  },
  /* eslint-enable no-param-reassign */
});
