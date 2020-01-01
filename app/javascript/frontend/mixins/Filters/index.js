import { debounce } from 'debounce'

export default {
  data() {
    return {
      booleanOptions: [{
        name: 'No',
        value: 'false',
      }, {
        name: 'Yes',
        value: 'true',
      }],

      priceOptions: [
        {
          value: '-200000',
          name: `< 200K ${this.$t('labels.uec')}`,
        }, {
          value: '200000-500000',
          name: `200K ${this.$t('labels.uec')} - 500K ${this.$t('labels.uec')}`,
        }, {
          value: '500000-2000000',
          name: `500K ${this.$t('labels.uec')} - 2M ${this.$t('labels.uec')}`,
        }, {
          value: '2000000-10000000',
          name: `2M ${this.$t('labels.uec')} - 10M ${this.$t('labels.uec')}`,
        }, {
          value: '10000000-25000000',
          name: `10M ${this.$t('labels.uec')} - 25M ${this.$t('labels.uec')}`,
        }, {
          value: '25000000-50000000',
          name: `25M ${this.$t('labels.uec')} - 50M ${this.$t('labels.uec')}`,
        }, {
          value: '50000000-100000000',
          name: `50M ${this.$t('labels.uec')} - 100M ${this.$t('labels.uec')}`,
        }, {
          value: '100000000-250000000',
          name: `100M ${this.$t('labels.uec')} - 250M ${this.$t('labels.uec')}`,
        }, {
          value: '250000000-500000000',
          name: `250M ${this.$t('labels.uec')} - 500M ${this.$t('labels.uec')}`,
        }, {
          value: '500000000-1000000000',
          name: `500M ${this.$t('labels.uec')} - 1B ${this.$t('labels.uec')}`,
        },
      ],

      pledgePriceOptions: [
        {
          value: '-25',
          name: '< $25',
        }, {
          value: '25-50',
          name: '$25 - $49',
        }, {
          value: '50-75',
          name: '$50 - $74',
        }, {
          value: '75-100',
          name: '$75 - $99',
        }, {
          value: '100-150',
          name: '$100 - $149',
        }, {
          value: '150-200',
          name: '$150 - $199',
        }, {
          value: '200-350',
          name: '$200 - $349',
        }, {
          value: '350-500',
          name: '$350 - $499',
        }, {
          value: '500-1000',
          name: '$500 - $999',
        }, {
          value: '1000-',
          name: '> $1000',
        },
      ],
    }
  },

  computed: {
    isPagePresent() {
      return !!this.$route.query.page
    },

    isFilterSelected() {
      const query = JSON.parse(JSON.stringify(this.$route.query.q || {}))

      Object.keys(query)
        .filter((key) => !query[key] || query[key].length === 0)
        .forEach((key) => delete query[key])

      return Object.keys(query).length > 0
    },

    q() {
      const q = JSON.parse(JSON.stringify(this.form))

      Object.keys(q)
        .filter((key) => !q[key] || q[key].length === 0)
        .forEach((key) => delete q[key])

      return q
    },
  },

  methods: {
    idFor(name) {
      const parts = name.split('-')
      if (this.prefix) {
        parts.unshift(this.prefix)
      }
      return parts.join('-')
    },

    resetFilter() {
      this.$router.replace({
        name: this.$route.name,
        query: {},
      }).catch((_err) => {})
    },

    resetPage() {
      const query = {
        ...JSON.parse(JSON.stringify(this.$route.query)),
      }

      if (query.page) {
        delete query.page
      }

      this.$router.replace({
        name: this.$route.name,
        query: {
          ...query,
          q: this.$route.query.q || {},
        },
      }).catch((_err) => {})
    },

    filter: debounce(function debounced() {
      this.$router.replace({
        name: this.$route.name,
        query: {
          ...this.$route.query,
          q: JSON.parse(JSON.stringify(this.q)),
        },
      }).catch((_err) => {})
    }, 500),
  },
}
