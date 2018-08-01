import { get } from 'frontend/lib/ApiClient'
import I18n from 'frontend/lib/I18n'

export default {
  getMessage() {
    return I18n.t('messages.error.handleNotFound')
  },
  validate(value) {
    return get(`rsi/citizens/${value}`, {})
      .then(({ data }) => ({
        valid: !!data,
      }))
      .catch(() => ({ valid: false }))
  },
}
