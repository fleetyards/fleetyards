<template>
  <section class="container fleet-detail" />
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import { publicFleetRouteGuard } from 'frontend/utils/RouteGuards'
import fleetsCollection from 'frontend/api/collections/Fleets'
import fleetInviteUrlCollection from 'frontend/api/collections/FleetInviteUrls'
import { displayAlert, displaySuccess } from 'frontend/lib/Noty'
import fleetMembersCollection from 'frontend/api/collections/FleetMembers'

@Component<FleetInvite>({
  beforeRouteEnter: publicFleetRouteGuard,
})
export default class FleetInvite extends Vue {
  @Getter('currentUser', { namespace: 'session' }) currentUser: User

  get fleet() {
    return fleetsCollection.record
  }

  @Watch('currentUser')
  onCurrentUserChange() {
    this.useInvite()
  }

  created() {
    this.useInvite()
  }

  async useInvite() {
    if (!this.currentUser) {
      return
    }

    await this.fetchFleet()

    const invite = await this.checkInvite()

    if (!invite) {
      displayAlert({
        text: this.$t('messages.fleetInvite.notFound'),
      })

      this.$router.push({
        name: 'fleet',
        params: { slug: this.$route.params.slug },
      })
      return
    }

    const member = await this.createMember()

    if (!member) {
      displayAlert({
        text: this.$t('messages.fleetInvite.failure'),
      })

      this.$router.push({
        name: 'fleet',
        params: { slug: this.$route.params.slug },
      })

      return
    }

    displaySuccess({
      text: this.$t('messages.fleetInvite.used', { fleet: this.fleet.name }),
    })

    this.$router.push({
      name: 'fleet',
      params: { slug: this.$route.params.slug },
    })
  }

  checkInvite(): Promise<boolean> {
    return fleetInviteUrlCollection.checkToken(
      this.$route.params.slug,
      this.$route.params.token,
    )
  }

  createMember(): Promise<FleetMember | null> {
    return fleetMembersCollection.createByInvite(this.$route.params.slug, {
      token: this.$route.params.token,
      username: this.currentUser.username,
    })
  }

  async fetchFleet() {
    await fleetsCollection.findBySlug(this.$route.params.slug)
  }
}
</script>
