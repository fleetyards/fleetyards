import I18n from 'i18n-js'
import en from 'translations/en'
import de from 'translations/de'
import { parseISO } from 'date-fns'
import { format } from 'date-fns-tz'

// @ts-ignore
I18n.availableLocales = ['en', 'de']
I18n.defaultLocale = 'en'
I18n.locale = 'en'
I18n.fallbacks = true
I18n.translations.en = en
I18n.translations.de = de

const methods = {
  t(key: string, options: Object) {
    return I18n.t(key, options)
  },

  l(value: string, dateFormat = 'datetime.formats.default') {
    return format(parseISO(value), I18n.t(dateFormat))
  },

  toNumber(value: number, units: string) {
    let count: string | number = I18n.l('number', value)
    if (units === 'weight') {
      count = I18n.l('number', value / 1000)
    }
    if (units === 'people') {
      count = value
    }
    if (units === 'speed' && value) {
      count = value
        // @ts-ignore
        .split(' - ')
        .map(item => I18n.l('number', item))
        .join(' - ')
    }
    if (!value || (['speed', 'rotation'].includes(units) && value <= 0)) {
      return I18n.t('labels.not-available')
    }
    return I18n.t(`number.${units}`, {
      count,
    })
  },

  toDollar(value: number) {
    return I18n.toCurrency(value, {
      precision: 2,
      unit: '$',
    })
  },

  toAu(value: number) {
    if (!value) {
      return '-'
    }
    return I18n.toCurrency(value, {
      precision: 2,
      unit: I18n.t('labels.au'),
      format: '%n %u',
    })
  },

  toUEC(value: number, unit: string) {
    if (!unit) {
      // eslint-disable-next-line no-param-reassign
      unit = I18n.t('labels.uec')
    }

    if (!value) {
      return '-'
    }

    return I18n.toCurrency(value, {
      precision: 2,
      unit,
      format: '%n %u',
    })
  },
}

export { I18n }

export default {
  install(Vue) {
    Object.keys(methods).forEach(methodName => {
      // eslint-disable-next-line no-param-reassign
      Vue.prototype[`$${methodName}`] = methods[methodName]
    })

    Vue.mixin({
      created() {
        if (this.$store && I18n.locale !== this.$store.state.locale) {
          I18n.locale = this.$store.state.locale
        }
      },
    })
  },
}
