import { mapGetters } from 'vuex'

export default {
  data() {
    return {
      sessionRenewInterval: null,
    }
  },
  computed: {
    ...mapGetters([
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
      this.$store.dispatch('renewSession')

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
        this.$store.dispatch('renewSession')
      }, 60 * 1000)
    },
  },
}
