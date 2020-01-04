import { post } from 'frontend/lib/ApiClient'
import { I18n } from 'frontend/lib/I18n'

export default {
  getMessage() {
    return I18n.t('messages.error.userNotFound')
  },
  validate(value) {
    return post('users/check-username', { username: value })
      .then(({ data }) => ({
        valid: data.usernameTaken,
      }))
      .catch(() => ({ valid: false }))
  },
}
