import { get } from 'frontend/lib/ApiClient'
import { I18n } from 'frontend/lib/I18n'

export default {
  getMessage() {
    return I18n.t('messages.error.fleetTaken')
  },
  validate(value) {
    return get(`fleets/${value}`, {})
      .then(({ data }) => ({
        valid: !data,
      }))
      .catch(() => ({ valid: true }))
  },
}
