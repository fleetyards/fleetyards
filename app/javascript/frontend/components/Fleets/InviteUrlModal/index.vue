<template>
  <Modal v-if="fleet" :title="$t('headlines.fleets.inviteUrls')">
    {{ inviteUrls }}
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
  @Prop({ required: true }) fleet: Fleet

  get inviteUrls() {
    return inviteUrlCollection.records
  }

  mounted() {
    this.fetch()
  }

  async fetch() {
    await inviteUrlCollection.findAll(this.fleet.slug)
  }
}
</script>
