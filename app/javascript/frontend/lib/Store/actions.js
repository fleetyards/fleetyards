export default {
  reset({ dispatch, commit }, hard = false) {
    commit('reset')
    dispatch('app/reset')

    if (hard) {
      dispatch('session/reset')
    }

    dispatch('hangar/reset')
    dispatch('models/reset')
    dispatch('tradehubs/reset')
    dispatch('stations/reset')
    dispatch('shops/reset')
    dispatch('shop/reset')
    dispatch('compare/reset')
  },
}
