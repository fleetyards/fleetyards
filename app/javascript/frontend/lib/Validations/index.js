import {
  ValidationProvider, ValidationObserver, extend, configure,
} from 'vee-validate'
/* eslint-disable camelcase */
import {
  required, email, alpha_dash, min, confirmed, regex,
} from 'vee-validate/dist/rules'
/* eslint-enable camelcase */
import { I18n } from 'frontend/lib/I18n'
import {
  emailTaken, fidTaken, user, usernameTaken,
} from './rules'

configure({
  defaultMessage(_, values) {
    return I18n.t(`validations.${values._rule_}`, values)
  },
})

export default {
  install(Vue) {
    Vue.component('ValidationObserver', ValidationObserver)
    Vue.component('ValidationProvider', ValidationProvider)

    extend('required', required)
    extend('alpha_dash', alpha_dash)
    extend('confirmed', confirmed)
    extend('regex', regex)
    extend('min', min)
    extend('email', email)
    extend('emailTaken', emailTaken)
    extend('usernameTaken', usernameTaken)
    extend('user', user)
    extend('fidTaken', fidTaken)
  },
}
