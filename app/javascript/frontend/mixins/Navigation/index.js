import { mapGetters } from 'vuex'

export default {
  computed: {
    ...mapGetters([
      'mobile',
    ]),

    ...mapGetters('app', [
      'navSlim',
    ]),

    ...mapGetters('session', [
      'currentUser',
      'isAuthenticated',
    ]),

    slim() {
      return this.navSlim && !this.mobile
    },
  },
}
