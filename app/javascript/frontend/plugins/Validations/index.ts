import {
  ValidationProvider,
  ValidationObserver,
  extend,
  configure,
} from 'vee-validate'
/* eslint-disable camelcase */
import {
  required,
  email,
  alpha_dash,
  numeric,
  between,
  min,
  min_value,
  confirmed,
  regex,
} from 'vee-validate/dist/rules'
/* eslint-enable camelcase */
import { I18n } from 'frontend/lib/I18n'
import {
  emailTaken,
  fidTaken,
  user,
  usernameTaken,
  url,
  hexColor,
} from './rules'

configure({
  defaultMessage(_, values) {
    return I18n.t(`validations.${values._rule_}`, values)
  },
})

export default {
  install(vue: any) {
    vue.component('ValidationObserver', ValidationObserver)
    vue.component('ValidationProvider', ValidationProvider)

    extend('required', required)
    extend('url', url)
    extend('alpha_dash', alpha_dash)
    extend('confirmed', confirmed)
    extend('regex', regex)
    extend('min', min)
    extend('min_value', min_value)
    extend('numeric', numeric)
    extend('between', between)
    extend('email', email)
    extend('emailTaken', emailTaken)
    extend('usernameTaken', usernameTaken)
    extend('user', user)
    extend('fidTaken', fidTaken)
    extend('hexColor', hexColor)
  },
}
