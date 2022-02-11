import debounce from 'lodash.debounce'

const getQuery = function getQuery(formData) {
  const q = JSON.parse(JSON.stringify(formData))

  Object.keys(q)
    .filter((key) => !q[key] || q[key].length === 0)
    .forEach((key) => delete q[key])

  return q
}

export default {
  data() {
    return {
      filter: debounce(this.debouncedFilter, 500),
      form: {},
    }
  },

  computed: {
    isFilterSelected() {
      const query = JSON.parse(JSON.stringify(this.$route.query.q || {}))

      Object.keys(query)
        .filter((key) => !query[key] || query[key].length === 0)
        .forEach((key) => delete query[key])

      return Object.keys(query).length > 0
    },
  },

  watch: {
    form: {
      deep: true,
      handler() {
        this.filter()
      },
    },
  },

  methods: {
    resetFilter() {
      this.$router
        .replace({
          name: this.$route.name || undefined,
          query: {},
        })
        .catch((_err) => {})
    },

    debouncedFilter() {
      this.$router
        .replace({
          name: this.$route.name || undefined,
          query: {
            ...this.$route.query,
            q: getQuery(this.form),
          },
        })
        .catch((_err) => {})
    },
  },
}
