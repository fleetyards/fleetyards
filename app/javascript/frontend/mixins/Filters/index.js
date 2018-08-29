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
    isFilterSelected() {
      const query = JSON.parse(JSON.stringify(this.$route.query.q || {}))
      Object.keys(query)
        .filter(key => !query[key] || query[key].length === 0)
        .forEach(key => delete query[key])
      return Object.keys(query).length > 0
    },
    q() {
      const q = JSON.parse(JSON.stringify(this.form))

      Object.keys(q)
        .filter(key => !q[key] || q[key].length === 0)
        .forEach(key => delete q[key])

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
    reset() {
      this.$router.replace({
        name: this.$route.name,
        query: {},
      })
    },
    filter() {
      const query = {
        q: JSON.parse(JSON.stringify(this.q)),
      }

      if (((this.isFilterSelected && Object.keys(this.q).length > 0)
        || (!this.isFilterSelected && Object.keys(this.q).length === 0))
        && this.$route.query.page) {
        query.page = this.$route.query.page
      }

      this.$router.replace({
        name: this.$route.name,
        query,
      })
    },
    fetchManufacturers({ page, search, missingValue }) {
      const query = {
        with_model: true,
        q: {},
      }
      if (search) {
        query.q.nameOrSlugCont = search
      } else if (missingValue) {
        query.q.nameOrSlugIn = missingValue
      } else if (page) {
        query.page = page
      }
      return this.$api.get('manufacturers', query)
    },
    fetchClassifications() {
      return this.$api.get('models/classifications')
    },
    fetchFocus() {
      return this.$api.get('models/focus')
    },
    fetchProductionStatus() {
      return this.$api.get('models/production-states')
    },
    fetchSize() {
      return this.$api.get('models/sizes')
    },
  },
}
