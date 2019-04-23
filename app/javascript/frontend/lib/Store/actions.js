import getDefaultState from './state'

export default {
  reset({ state, dispatch }) {
    Object.assign(state, getDefaultState())
    dispatch('app/reset')
    dispatch('session/reset')
    dispatch('hangar/reset')
    dispatch('models/reset')
    dispatch('tradehubs/reset')
    dispatch('stations/reset')
    dispatch('shops/reset')
    dispatch('shop/reset')
    dispatch('compare/reset')
  },
}
