import { mapGetters } from 'vuex'
import { parseISO, isBefore } from 'date-fns'

export default {
  data() {
    return {
      sessionRenewInterval: null,
    }
  },

  computed: {
    ...mapGetters('session', ['isAuthenticated', 'authTokenRenewAt']),
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
      this.renew()

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
        this.renew()
      }, 60 * 1000)
    },

    async renew() {
      if (
        this.authTokenRenewAt &&
        isBefore(new Date(), parseISO(this.authTokenRenewAt))
      ) {
        return
      }

      const response = await this.$api.put('sessions/renew')
      if (!response.error) {
        this.$store.dispatch('session/login', response.data)
      }
    },
  },
}
