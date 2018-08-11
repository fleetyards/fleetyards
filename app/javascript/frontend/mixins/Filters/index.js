export default {
  computed: {
    isFilterSelected() {
      const query = JSON.parse(JSON.stringify(this.$route.query.q || {}))
      Object.keys(query)
        .filter(key => !query[key] || query[key].length === 0)
        .forEach(key => delete query[key])
      return Object.keys(query).length > 0
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
    openFilter() {
      if (!this.$refs.filterModal) {
        return
      }
      this.$refs.filterModal.open()
    },
  },
}
