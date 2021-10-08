import { I18n } from 'frontend/lib/I18n'

const regex: RegExp = /^[0-9A-ZÀÂÆÇÉÈÊËÏÎÔŒÙÛÜŸÄÖßÁÍÑÓÚ\-_'"\.,\?!:;\/\s]*$/i

const validate = (value: string): boolean => regex.test(value)

export { validate }

export default {
  message(field) {
    return I18n.t('messages.error.textInvalid', { field })
  },
  validate,
}
