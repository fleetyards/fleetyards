import I18n from 'i18n-js'
import en from 'translations/en.json'

I18n.fallbacks = true
I18n.defaultLocale = 'en'
I18n.locale = 'en'
I18n.translations.en = en

const methods = {
  t(key, options) {
    return I18n.t(key, options)
  },
  l(value, format = 'datetime.formats.default') {
    return I18n.toTime(format, value)
  },
  toNumber(value, units) {
    let count = I18n.l('number', value)
    if (units === 'weight') {
      count = I18n.l('number', (value / 1000))
    }
    if (units === 'people') {
      count = value
    }
    if (units === 'speed' && value) {
      count = value.split(' - ').map(item => I18n.l('number', item)).join(' - ')
    }
    if (!value || (['speed', 'rotation'].includes(units) && value <= 0)) {
      return I18n.t('labels.not-available')
    }
    return I18n.t(`number.${units}`, { count })
  },
  toDollar(value) {
    return I18n.toCurrency(value, {
      precision: 2,
      unit: '$',
    })
  },
  toAu(value) {
    if (!value) {
      return '-'
    }
    return I18n.toCurrency(value, {
      precision: 2,
      unit: I18n.t('labels.au'),
      format: '%n %u',
    })
  },
  toUEC(value) {
    if (!value) {
      return '-'
    }
    return I18n.toCurrency(value, {
      precision: 2,
      unit: I18n.t('labels.uec'),
      format: '%n %u',
    })
  },
}

export { I18n }

export default {
  install(Vue) {
    Object.keys(methods).forEach((methodName) => {
      // eslint-disable-next-line no-param-reassign
      Vue.prototype[`$${methodName}`] = methods[methodName]
    })

    Vue.mixin({
      created () {
        if (this.$store && I18n.locale !== this.$store.state.locale) {
          I18n.locale = this.$store.state.locale
        }
      },
    })
  },
}
