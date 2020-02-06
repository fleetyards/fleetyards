const CHECK_VERSION_INTERVAL = 60 * 1000 // 60s

export default {
  created() {
    this.checkVersion()

    setInterval(() => {
      this.checkVersion()
    }, CHECK_VERSION_INTERVAL)
  },

  methods: {
    async checkVersion() {
      const response = await this.$api.get('version', null, true)
      if (!response.error) {
        this.$store.dispatch('app/updateVersion', response.data)
      }
    },
  },
}
