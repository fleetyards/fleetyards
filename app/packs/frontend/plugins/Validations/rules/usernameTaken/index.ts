import { post } from 'frontend/api/client'
import { I18n } from 'frontend/lib/I18n'

export default {
  message() {
    return I18n.t('messages.error.usernameTaken')
  },
  validate(value: string) {
    return post('users/check-username', { username: value }, true)
      .then(({ data }) => ({
        valid: !data.usernameTaken,
      }))
      .catch(() => ({ valid: true }))
  },
}
