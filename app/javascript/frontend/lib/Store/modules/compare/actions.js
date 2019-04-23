import getDefaultState from './state'

export default {
  reset({ state }) {
    Object.assign(state, getDefaultState())
  },
}
