<template>
  <Modal v-if="fleet" :title="$t('headlines.fleets.inviteUrls')">
    <div
      v-for="inviteUrl in inviteUrls"
      :key="inviteUrl.token"
      class="invite-url"
    >
      <FormInput
        :id="inviteUrl.token"
        v-model="inviteUrl.url"
        :disabled="true"
        :no-label="true"
        :inline="true"
        @click.native="copy(inviteUrl)"
      />
      <div class="invite-url-counter">
        {{ inviteCount(inviteUrl) }}
        <i class="fad fa-user" />
      </div>
      <Btn size="small" @click.native="copy(inviteUrl)">
        <i class="fad fa-copy" />
      </Btn>
      <Btn size="small" @click.native="remove(inviteUrl)">
        <i class="fad fa-trash" />
      </Btn>
    </div>
    <Btn @click.native="create">Create</Btn>
  </Modal>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import copyText from 'frontend/utils/CopyText'
import Modal from 'frontend/core/components/AppModal/Modal'
import Btn from 'frontend/core/components/Btn'
import FormInput from 'frontend/core/components/Form/FormInput'
import inviteUrlCollection from 'frontend/api/collections/FleetInviteUrls'
import { displayAlert, displaySuccess } from 'frontend/lib/Noty'

@Component<MemberModal>({
  components: {
    Modal,
    Btn,
    FormInput,
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

  async create() {
    await this.collection.create(this.fleet.slug, true)
  }

  async remove(inviteUrl) {
    await this.collection.destroy(this.fleet.slug, inviteUrl.token, true)
  }

  inviteCount(inviteUrl) {
    if (inviteUrl.inviteCount > 999) {
      return '+999'
    }

    return inviteUrl.inviteCount
  }

  copy(inviteUrl) {
    copyText(inviteUrl.url).then(
      () => {
        displaySuccess({
          text: this.$t('messages.copyInviteUrl.success', {
            url: inviteUrl.url,
          }),
        })
      },
      () => {
        displayAlert({
          text: this.$t('messages.copyInviteUrl.failure'),
        })
      },
    )
  }
}
</script>

<style lang="scss" scoped>
.invite-url {
  display: flex;
  align-content: center;
  justify-content: space-between;

  .invite-url-counter {
    display: flex;
    align-items: center;
    justify-content: flex-end;
    min-width: 60px;
    margin-right: 10px;
    margin-bottom: 20px;
    margin-left: 10px;

    i {
      margin-left: 10px;
    }
  }
}
</style>
