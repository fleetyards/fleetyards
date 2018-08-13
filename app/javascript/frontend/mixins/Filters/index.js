export default {
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
    openFilter() {
      if (!this.$refs.filterModal) {
        return
      }
      this.$refs.filterModal.open()
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
  },
}
