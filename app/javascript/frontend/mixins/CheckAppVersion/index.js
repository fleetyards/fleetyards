export default {
  created() {
    this.fetchAppVersion()
  },
  methods: {
    async fetchAppVersion() {
      const response = await this.$api.get('version')
      if (!response.error) {
        this.$store.dispatch('updateAppVersion', response.data)
      }
    },
  },
}
