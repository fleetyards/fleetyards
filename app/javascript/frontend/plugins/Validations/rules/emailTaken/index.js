import { post } from 'frontend/api/client'
import { I18n } from 'frontend/lib/I18n'

export default {
  message() {
    return I18n.t('messages.error.emailTaken')
  },
  validate(value) {
    return post('users/check-email', { email: value })
      .then(({ data }) => ({
        valid: !data.emailTaken,
      }))
      .catch(() => ({ valid: true }))
  },
}
