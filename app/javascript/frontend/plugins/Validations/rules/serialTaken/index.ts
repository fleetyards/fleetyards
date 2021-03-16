import { post } from 'frontend/api/client'
import { I18n } from 'frontend/lib/I18n'

export default {
  message() {
    return I18n.t('messages.error.serialTaken')
  },
  validate(value) {
    return post('vehicles/check-serial', { serial: value })
      .then(({ data }) => ({
        valid: !data.serialTaken,
      }))
      .catch(() => ({ valid: true }))
  },
}
