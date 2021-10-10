<template>
  <div v-if="member" class="fade-list-item col-12 flex-list-item">
    <div class="flex-list-row">
      <div class="username">
        <Avatar :avatar="member.avatar" size="small" />
        {{ member.username }}
        <template v-if="mobile">
          (
          <a
            v-if="member.rsiHandle"
            v-tooltip="$t('nav.rsiProfile')"
            :href="
              `https://robertsspaceindustries.com/citizens/${member.rsiHandle}`
            "
            target="_blank"
            rel="noopener"
          >
            {{ member.rsiHandle }}
          </a>
          )
        </template>
      </div>
      <div v-if="!mobile" class="rsi-handle">
        <a
          v-if="member.rsiHandle"
          v-tooltip="$t('nav.rsiProfile')"
          :href="
            `https://robertsspaceindustries.com/citizens/${member.rsiHandle}`
          "
          target="_blank"
          rel="noopener"
        >
          {{ member.rsiHandle }}
        </a>
      </div>
      <div class="role">
        <template v-if="member.status === 'invited'">
          {{ $t('labels.fleet.members.invited') }}
        </template>
        <template v-else-if="member.status === 'requested'">
          {{ $t('labels.fleet.members.requested') }}
        </template>
        <span v-else-if="member.status === 'declined'" class="text-danger">
          {{ $t('labels.fleet.members.declined') }}
        </span>
        <template v-else>
          {{ member.roleLabel }}
        </template>
      </div>
      <div class="joined">
        <template v-if="member.status === 'invited'">
          {{ member.invitedAtLabel }}
        </template>
        <template v-else-if="member.status === 'declined'">
          {{ member.declinedAtLabel }}
        </template>
        <template v-else-if="member.status === 'requested'">
          {{ member.requestedAtLabel }}
        </template>
        <template v-else>
          {{ member.acceptedAtLabel }}
        </template>
      </div>
      <div class="links">
        <a
          v-tooltip="$t('labels.hangar')"
          :href="`/hangar/${member.username}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fad fa-bookmark" />
        </a>
        <a
          v-if="member.homepage"
          v-tooltip="$t('labels.homepage')"
          :href="member.homepage"
          target="_blank"
          rel="noopener"
        >
          <i class="fal fa-globe globe-rotate" />
        </a>
        <a
          v-if="member.rsiHandle"
          v-tooltip="$t('nav.rsiProfile')"
          :href="
            `https://robertsspaceindustries.com/citizens/${member.rsiHandle}`
          "
          target="_blank"
          rel="noopener"
        >
          <i class="icon icon-rsi icon-small" />
        </a>
        <a
          v-if="member.youtube"
          v-tooltip="$t('labels.youtube')"
          :href="member.youtube"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-youtube" />
        </a>
        <a
          v-if="member.twitch"
          v-tooltip="$t('labels.twitch')"
          :href="member.twitch"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-twitch" />
        </a>
        <a
          v-if="member.guilded"
          v-tooltip="$t('labels.guilded')"
          :href="member.guilded"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-guilded" />
        </a>
        <a
          v-if="member.discord"
          v-tooltip="$t('labels.discord')"
          :href="member.discord"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-discord" />
        </a>
      </div>
      <div v-if="editable" class="actions actions-3x">
        <Btn
          v-if="member.status === 'requested'"
          v-tooltip="$t('actions.fleet.members.accept')"
          size="small"
          :disabled="!editableMember || updating"
          :inline="true"
          @click.native="acceptRequest(member)"
        >
          <i class="fal fa-check" />
        </Btn>
        <Btn
          v-if="member.status === 'requested'"
          v-tooltip="$t('actions.fleet.members.decline')"
          size="small"
          :disabled="!editableMember || updating"
          :inline="true"
          @click.native="declineRequest(member)"
        >
          <i class="fal fa-times" />
        </Btn>
        <Btn
          v-if="member.role !== 'admin' && member.status === 'accepted'"
          v-tooltip="$t('actions.fleet.members.promote')"
          size="small"
          :disabled="!editableMember || updating"
          :inline="true"
          @click.native="promoteMember(member)"
        >
          <i class="fal fa-chevron-up" />
        </Btn>
        <Btn
          v-if="member.role !== 'member' && member.status === 'accepted'"
          v-tooltip="$t('actions.fleet.members.demote')"
          size="small"
          :disabled="!editableMember || updating"
          :inline="true"
          @click.native="demoteMember(member)"
        >
          <i class="fal fa-chevron-down" />
        </Btn>
        <Btn
          size="small"
          :disabled="!editableMember || deleting"
          :inline="true"
          @click.native="removeMember(member)"
        >
          <i class="fad fa-trash-alt" />
        </Btn>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import Avatar from 'frontend/core/components/Avatar'
import Btn from 'frontend/core/components/Btn'
import { displaySuccess, displayAlert, displayConfirm } from 'frontend/lib/Noty'
import fleetMembersCollection from 'frontend/api/collections/FleetMembers'

@Component<MembersListItem>({
  components: {
    Avatar,
    Btn,
  },
})
export default class MembersListItem extends Vue {
  collection: FleetMembersCollection = fleetMembersCollection

  deleting: boolean = false

  updating: boolean = false

  @Getter('mobile') mobile

  @Prop({ required: true }) member: Member

  @Prop({ default: false }) editable: boolean

  @Prop({ default: false }) editableMember: boolean

  async removeMember(member) {
    this.deleting = true
    displayConfirm({
      text: this.$t('messages.confirm.fleet.members.destroy'),
      onConfirm: async () => {
        const response = await this.$api.destroy(
          `fleets/${this.$route.params.slug}/members/${member.username}`,
        )

        if (!response.error) {
          this.$comlink.$emit('fleet-member-update')
          displaySuccess({
            text: this.$t('messages.fleet.members.destroy.success'),
          })
        } else {
          displayAlert({
            text: this.$t('messages.fleet.members.destroy.failure'),
          })
          this.deleting = false
        }
      },
      onClose: () => {
        this.deleting = false
      },
    })
  }

  async demoteMember(member) {
    this.updating = true

    const response = await this.$api.put(
      `fleets/${this.$route.params.slug}/members/${member.username}/demote`,
    )

    this.updating = false

    if (!response.error) {
      this.$comlink.$emit('fleet-member-update')
      displaySuccess({
        text: this.$t('messages.fleet.members.demote.success'),
      })
    } else {
      displayAlert({
        text: this.$t('messages.fleet.members.demote.failure'),
      })
    }
  }

  async promoteMember(member) {
    this.updating = true

    const response = await this.$api.put(
      `fleets/${this.$route.params.slug}/members/${member.username}/promote`,
    )

    this.updating = false

    if (!response.error) {
      this.$comlink.$emit('fleet-member-update')
      displaySuccess({
        text: this.$t('messages.fleet.members.promote.success'),
      })
    } else {
      displayAlert({
        text: this.$t('messages.fleet.members.promote.failure'),
      })
    }
  }

  async acceptRequest(member) {
    this.updating = true

    const success = await this.collection.acceptRequest(
      this.$route.params.slug,
      member.username,
    )

    this.updating = false

    if (success) {
      this.$comlink.$emit('fleet-member-update')
      displaySuccess({
        text: this.$t('messages.fleet.members.accept.success'),
      })
    } else {
      displayAlert({
        text: this.$t('messages.fleet.members.accept.failure'),
      })
    }
  }

  async declineRequest(member) {
    this.updating = true

    const success = await this.collection.declineRequest(
      this.$route.params.slug,
      member.username,
    )

    this.updating = false

    if (success) {
      this.$comlink.$emit('fleet-member-update')
      displaySuccess({
        text: this.$t('messages.fleet.members.decline.success'),
      })
    } else {
      displayAlert({
        text: this.$t('messages.fleet.members.decline.failure'),
      })
    }
  }
}
</script>

<style lang="scss" scoped>
@import '~stylesheets/variables';

@media (max-width: $desktop-breakpoint) {
  .flex-list-row {
    flex-direction: row !important;
    flex-wrap: wrap;
  }
}
</style>
