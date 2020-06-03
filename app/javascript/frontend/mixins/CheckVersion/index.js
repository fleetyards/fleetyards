const CHECK_VERSION_INTERVAL = 1800 * 1000 // 30 mins

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
