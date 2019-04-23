import { mapGetters } from 'vuex'

export default {
  computed: {
    ...mapGetters('session', [
      'isAuthenticated',
      'currentUser',
      'citizen',
    ]),
  },
  methods: {
    async fetchCurrentUser() {
      if (!this.isAuthenticated) {
        return
      }

      const response = await this.$api.get('users/current')
      if (!response.error) {
        this.$store.commit('session/setCurrentUser', response.data)
        if (this.currentUser.rsiHandle) {
          this.fetchCitizen()
        } else {
          this.$store.dispatch('session/resetCitizen')
        }
      }
    },
    async fetchCitizen() {
      if (!this.currentUser.rsiHandle) {
        return
      }

      const response = await this.$api.get(`rsi/citizens/${this.currentUser.rsiHandle}`)
      if (!response.error) {
        this.$store.commit('session/setCitizen', response.data)
      } else {
        this.$store.dispatch('session/resetCitizen')
      }
    },
  },
  watch: {
    isAuthenticated: 'fetchCurrentUser',
  },
  created() {
    this.fetchCurrentUser()
    this.$comlink.$on('userUpdate', this.fetchCurrentUser)
  },
}
