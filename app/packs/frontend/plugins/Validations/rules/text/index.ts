import { I18n } from 'frontend/lib/I18n'

const regex: RegExp =
  /^[\d\w\bÀÂÆÇÉÈÊËÏÎÔŒÙÛÜŸÄÖßÁÍÑÓÚàâæçéèêëïîôœùûüÿäöáíñóú\[\]\(\)-_'".,?!:;\s]*$/i

const validate = (value: string): boolean => regex.test(value)

export { validate }

export default {
  message(field) {
    return I18n.t('messages.error.textInvalid', { field })
  },
  validate,
}
