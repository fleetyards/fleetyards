import { mapGetters } from 'vuex'

export default {
  computed: {
    ...mapGetters([
      'isAuthenticated',
      'currentUser',
      'citizen',
    ]),
  },
  methods: {
    fetchCurrentUser() {
      if (!this.isAuthenticated) {
        return
      }
      this.$api.get('users/current', {}, (args) => {
        if (!args.error) {
          this.$store.commit('setCurrentUser', args.data)
          if (this.currentUser.rsiHandle) {
            this.fetchCitizen()
          } else {
            this.$store.commit('resetCitizen')
          }
        }
      })
    },
    fetchCitizen() {
      if (!this.currentUser.rsiHandle) {
        return
      }

      this.$api.get(`rsi/citizens/${this.currentUser.rsiHandle}`, {}, (args) => {
        if (!args.error) {
          this.$store.commit('setCitizen', args.data)
        } else {
          this.$store.commit('resetCitizen')
        }
      })
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
