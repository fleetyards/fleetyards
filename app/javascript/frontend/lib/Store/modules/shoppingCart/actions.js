export default {
  reset({ commit }) {
    commit('reset')
  },

  add({ commit }, payload) {
    commit('add', payload)
  },

  remove({ commit }, payload) {
    commit('remove', payload)
  },

  clear({ commit }) {
    commit('setItems', [])
  },
}
