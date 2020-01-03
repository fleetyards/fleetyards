import { mapGetters } from 'vuex'

export default {
  computed: {
    ...mapGetters('session', [
      'isAuthenticated',
      'currentUser',
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
      }
    },
  },

  watch: {
    isAuthenticated: 'fetchCurrentUser',
  },

  created() {
    this.fetchCurrentUser()
    this.$comlink.$on('userUpdate', this.fetchCurrentUser)
    this.$comlink.$on('fleetCreate', this.fetchCurrentUser)
    this.$comlink.$on('fleetUpdate', this.fetchCurrentUser)
  },
}
