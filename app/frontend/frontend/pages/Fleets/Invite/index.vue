<template>
  <section class="container fleet-detail" />
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import fleetsCollection from '@/frontend/api/collections/Fleets'
import {
  displayConfirm,
  displayAlert,
  displaySuccess,
} from '@/frontend/lib/Noty'

export default {
  name: 'FleetInvite',

  computed: {
    ...mapGetters('session', ['currentUser']),
  },

  watch: {
    currentUser() {
      this.useInvite()
    },
  },

  mounted() {
    this.useInvite()
  },

  methods: {
    ...mapActions('fleet', {
      resetFleetInviteToken: 'resetInviteToken',
    }),

    async useInvite() {
      if (!this.currentUser) {
        return
      }

      const fleet = await this.checkInvite()

      if (!fleet) {
        displayAlert({
          text: this.$t('messages.fleetInvite.notFound'),
        })

        this.$router.push({
          name: 'home',
        })

        return
      }

      displayConfirm({
        text: this.$t('messages.fleetInvite.confirm', {
          fleet: fleet.name,
        }),
        onConfirm: () => {
          this.handleFleetInvite()
        },
        onClose: () => {
          this.$router.push({
            name: 'home',
          })
        },
      })
    },

    async handleFleetInvite() {
      const member = await this.createMember()

      if (!member) {
        displayAlert({
          text: this.$t('messages.fleetInvite.failure'),
        })

        this.$router.push({
          name: 'home',
        })

        return
      }

      this.resetFleetInviteToken()

      displaySuccess({
        text: this.$t('messages.fleetInvite.used', { fleet: member.fleetName }),
      })

      this.$router.push({
        name: 'fleet',
        params: { slug: member.fleetSlug },
      })
    },

    checkInvite() {
      return fleetsCollection.checkInvite(this.$route.params.token)
    },

    createMember() {
      return fleetsCollection.useInvite({
        token: this.$route.params.token,
        username: this.currentUser.username,
      })
    },
  },
}
</script>
