import { mapGetters } from 'vuex'

export default {
  computed: {
    ...mapGetters([
      'currentUser',
    ]),
    myOrg() {
      if (!this.currentUser || !this.$route.params.sid) {
        return false
      }
      return (this.currentUser.orgs || []).includes(this.$route.params.sid.toUpperCase())
    },
    myFleet() {
      if (!this.currentUser || !this.$route.params.sid) {
        return false
      }
      return (this.currentUser.fleets || []).includes(this.$route.params.sid.toLowerCase())
    },
    isMember() {
      if (!this.currentUser) {
        return false
      }

      return (this.myOrg && this.currentUser.rsiVerified) || this.myFleet
    },
  },
}
