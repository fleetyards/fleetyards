<template>
  <section class="container fleet-detail" />
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter, Action } from 'vuex-class'
import fleetsCollection from 'frontend/api/collections/Fleets'
import { displayAlert, displaySuccess } from 'frontend/lib/Noty'

@Component<FleetInvite>()
export default class FleetInvite extends Vue {
  @Getter('currentUser', { namespace: 'session' }) currentUser: User

  @Action('resetInviteToken', { namespace: 'fleet' }) resetFleetInviteToken: any

  @Watch('currentUser')
  onCurrentUserChange() {
    this.useInvite()
  }

  mounted() {
    this.useInvite()
  }

  async useInvite() {
    if (!this.currentUser) {
      return
    }

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
  }

  createMember(): Promise<FleetMember | null> {
    return fleetsCollection.useInvite({
      token: this.$route.params.token,
      username: this.currentUser.username,
    })
  }
}
</script>
