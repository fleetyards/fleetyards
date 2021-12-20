import { I18n } from 'frontend/lib/I18n'

const pattern = new RegExp(
  '^(https?:\\/\\/)?' + // protocol
    '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|' + // domain name
    '((\\d{1,3}\\.){3}\\d{1,3}))' + // OR ip (v4) address
    '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*' + // port and path
    '(\\?[;&a-z\\d%_.~+=-]*)?' + // query string
    '(\\#[-a-z\\d_]*)?$',
  'i' // fragment locator
)

export default {
  validate: (str) => !!pattern.test(str),
  message() {
    return I18n.t('messages.error.urlInvalid')
  },
}
