import { mapGetters } from 'vuex'

export default {
  computed: {
    ...mapGetters('session', ['currentUser']),

    fleets() {
      if (!this.currentUser) {
        return []
      }

      return this.currentUser.fleets || []
    },

    myFleets() {
      return this.fleets.filter(fleet => !fleet.invitation)
    },

    myFleet() {
      return this.myFleets.find(fleet => fleet.slug === this.$route.params.slug)
    },

    myFleetRole() {
      if (!this.myFleet) {
        return null
      }

      return this.myFleet.role
    },
  },
}
