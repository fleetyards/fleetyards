import actions from "./actions";
import getDefaultState from "./state";

export default () => ({
  namespaced: true,

  state: getDefaultState(),

  actions,

  getters: {
    ships(state) {
      return state.ships;
    },

    empty(state) {
      return state.ships.length === 0;
    },

    detailsVisible(state) {
      return state.detailsVisible;
    },

    filterVisible(state) {
      return state.filterVisible;
    },

    perPage(state) {
      return state.perPage;
    },

    gridView(state) {
      return state.gridView;
    },
  },

  /* eslint-disable no-param-reassign */
  mutations: {
    reset(state) {
      Object.assign(state, getDefaultState());
    },

    add(state, payload) {
      state.ships.push(payload);
    },

    remove(state, payload) {
      state.ships.splice(state.ships.indexOf(payload), 1);
    },

    setDetailsVisible(state, payload) {
      state.detailsVisible = payload;
    },

    setFilterVisible(state, payload) {
      state.filterVisible = payload;
    },

    setShips(state, payload) {
      state.ships = payload;
    },

    setPerPage(state, payload) {
      state.perPage = payload;
    },

    setGridView(state, payload) {
      state.gridView = payload;
    },
  },
  /* eslint-enable no-param-reassign */
});
