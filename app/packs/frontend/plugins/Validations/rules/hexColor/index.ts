import { I18n } from 'frontend/lib/I18n'

const pattern = /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/

export default {
  validate: (str) => !!pattern.test(str),
  message() {
    return I18n.t('messages.error.colorInvalid')
  },
}
