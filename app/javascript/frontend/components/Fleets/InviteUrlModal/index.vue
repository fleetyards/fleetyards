<template>
  <Modal v-if="fleet" :title="$t('headlines.fleets.inviteUrls')">
    <div v-for="inviteUrl in inviteUrls" :key="inviteUrl.token">
      {{ inviteUrl.url }} {{ inviteUrl.inviteCount }}
    </div>
    <Btn @click.native="createInviteUrl">Create</Btn>
  </Modal>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Modal from 'frontend/core/components/AppModal/Modal'
import Btn from 'frontend/core/components/Btn'
import inviteUrlCollection from 'frontend/api/collections/FleetInviteUrls'

@Component<MemberModal>({
  components: {
    Modal,
    Btn,
  },
})
export default class MemberModal extends Vue {
  collection: FleetInviteUrlCollection = inviteUrlCollection

  @Prop({ required: true }) fleet: Fleet

  get inviteUrls() {
    return this.collection.records
  }

  mounted() {
    this.fetch()
  }

  async fetch() {
    await this.collection.findAll({
      fleetSlug: this.fleet.slug,
    })
  }

  async createInviteUrl() {
    await this.collection.create(this.fleet.slug, true)
  }
}
</script>
