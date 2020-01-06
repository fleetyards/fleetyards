import { post } from 'frontend/lib/ApiClient'
import { I18n } from 'frontend/lib/I18n'

export default {
  getMessage() {
    return I18n.t('messages.error.fleetTaken')
  },
  validate(value) {
    return post('fleets/check', { name: value }, true)
      .then(({ data }) => ({
        valid: !data.taken,
      }))
      .catch(() => ({ valid: true }))
  },
}
