import getDefaultState from './state'

export default {
  reset({ state }) {
    Object.assign(state, getDefaultState())
  },

  add({ state }, payload) {
    state.errors.push(payload)
  },
}
