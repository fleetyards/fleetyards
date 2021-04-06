import { post } from 'frontend/api/client'
import { I18n } from 'frontend/lib/I18n'

export default {
  message() {
    return I18n.t('messages.error.fleetTaken')
  },
  validate(value) {
    return post('fleets/check', { fid: value }, true)
      .then(({ data }) => ({
        valid: !data.taken,
      }))
      .catch(() => ({ valid: true }))
  },
}
