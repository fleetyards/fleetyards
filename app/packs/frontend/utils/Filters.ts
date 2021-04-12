import { I18n } from 'frontend/lib/I18n'

export const booleanOptions = [
  {
    name: I18n.t('labels.false'),
    value: 'false',
  },
  {
    name: I18n.t('labels.true'),
    value: 'true',
  },
]

export const priceOptions = [
  {
    value: '-200000',
    name: `< 200K ${I18n.t('labels.uec')}`,
  },
  {
    value: '200000-500000',
    name: `200K ${I18n.t('labels.uec')} - 500K ${I18n.t('labels.uec')}`,
  },
  {
    value: '500000-2000000',
    name: `500K ${I18n.t('labels.uec')} - 2M ${I18n.t('labels.uec')}`,
  },
  {
    value: '2000000-10000000',
    name: `2M ${I18n.t('labels.uec')} - 10M ${I18n.t('labels.uec')}`,
  },
  {
    value: '10000000-25000000',
    name: `10M ${I18n.t('labels.uec')} - 25M ${I18n.t('labels.uec')}`,
  },
  {
    value: '25000000-50000000',
    name: `25M ${I18n.t('labels.uec')} - 50M ${I18n.t('labels.uec')}`,
  },
  {
    value: '50000000-100000000',
    name: `50M ${I18n.t('labels.uec')} - 100M ${I18n.t('labels.uec')}`,
  },
  {
    value: '100000000-250000000',
    name: `100M ${I18n.t('labels.uec')} - 250M ${I18n.t('labels.uec')}`,
  },
  {
    value: '250000000-500000000',
    name: `250M ${I18n.t('labels.uec')} - 500M ${I18n.t('labels.uec')}`,
  },
  {
    value: '500000000-1000000000',
    name: `500M ${I18n.t('labels.uec')} - 1B ${I18n.t('labels.uec')}`,
  },
]

export const pledgePriceOptions = [
  {
    value: '-25',
    name: '< $25',
  },
  {
    value: '25-50',
    name: '$25 - $49',
  },
  {
    value: '50-75',
    name: '$50 - $74',
  },
  {
    value: '75-100',
    name: '$75 - $99',
  },
  {
    value: '100-150',
    name: '$100 - $149',
  },
  {
    value: '150-200',
    name: '$150 - $199',
  },
  {
    value: '200-350',
    name: '$200 - $349',
  },
  {
    value: '350-500',
    name: '$350 - $499',
  },
  {
    value: '500-1000',
    name: '$500 - $999',
  },
  {
    value: '1000-',
    name: '> $1000',
  },
]
