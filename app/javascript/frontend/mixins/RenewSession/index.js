import { mapGetters } from 'vuex'

export default {
  data() {
    return {
      sessionRenewInterval: null,
    }
  },
  computed: {
    ...mapGetters('session', [
      'isAuthenticated',
    ]),
  },
  watch: {
    isAuthenticated() {
      if (this.isAuthenticated) {
        this.setupSessionRenewInterval()
      } else if (this.sessionRenewInterval) {
        clearInterval(this.sessionRenewInterval)
      }
    },
  },
  created() {
    if (this.isAuthenticated) {
      this.$store.dispatch('session/renew')

      this.setupSessionRenewInterval()
    }
  },
  beforeDestroy() {
    if (this.sessionRenewInterval) {
      clearInterval(this.sessionRenewInterval)
    }
  },
  methods: {
    setupSessionRenewInterval() {
      if (this.sessionRenewInterval) {
        return
      }

      this.sessionRenewInterval = setInterval(() => {
        this.$store.dispatch('session/renew')
      }, 60 * 1000)
    },
  },
}
