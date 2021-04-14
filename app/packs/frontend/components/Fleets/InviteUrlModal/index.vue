<template>
  <Modal v-if="fleet" :title="$t('headlines.fleets.inviteUrls')">
    <div
      v-for="inviteUrl in inviteUrls"
      :key="inviteUrl.token"
      class="invite-url"
    >
      <div class="invite-url-main">
        <FormInput
          :id="inviteUrl.token"
          v-model="inviteUrl.url"
          :disabled="true"
          :no-label="true"
          :inline="true"
          class="url-input"
          @click.native="copy(inviteUrl)"
        />
        <Btn size="small" :inline="true" @click.native="copy(inviteUrl)">
          <i class="fad fa-copy" />
        </Btn>
        <Btn size="small" :inline="true" @click.native="remove(inviteUrl)">
          <i class="fad fa-trash" />
        </Btn>
      </div>
      <div class="invite-url-subline">
        <div v-if="inviteUrl.expired">
          {{ $t('labels.fleet.inviteUrls.expired') }}
        </div>
        <div v-else-if="inviteUrl.expiresAfterLabel">
          {{
            $t('labels.fleet.inviteUrls.expiresIn', {
              time: inviteUrl.expiresAfterLabel,
            })
          }}
        </div>
        <div v-else>
          {{ $t('labels.fleet.inviteUrls.noExpiration') }}
        </div>
        <div>{{ usesLeft(inviteUrl) }}</div>
      </div>
    </div>

    <template v-if="form">
      <hr />
      <FilterGroup
        v-model="form.expiresAfterMinutes"
        :options="expiresAfterOptions"
        :label="$t('labels.filters.fleets.inviteUrls.expiresAfter')"
        name="expires-after"
      />
      <FilterGroup
        v-model="form.limit"
        :options="limitOptions"
        :label="$t('labels.filters.fleets.inviteUrls.limit')"
        name="limit"
      />
      <Btn @click.native="create">
        {{ $t('actions.fleet.inviteUrls.create') }}
      </Btn>
    </template>
  </Modal>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import copyText from 'frontend/utils/CopyText'
import Modal from 'frontend/core/components/AppModal/Modal'
import Btn from 'frontend/core/components/Btn'
import FormInput from 'frontend/core/components/Form/FormInput'
import FilterGroup from 'frontend/core/components/Form/FilterGroup'
import inviteUrlCollection from 'frontend/api/collections/FleetInviteUrls'
import { displayAlert, displaySuccess } from 'frontend/lib/Noty'

@Component<MemberModal>({
  components: {
    Modal,
    Btn,
    FormInput,
    FilterGroup,
  },
})
export default class MemberModal extends Vue {
  collection: FleetInviteUrlCollection = inviteUrlCollection

  @Prop({ required: true }) fleet: Fleet

  form: InviteUrlForm | null = null

  expiresAfterOptions = [
    {
      name: this.$t('labels.fleet.inviteUrls.expiresAfterOptions.infinite'),
      value: null,
    },
    {
      name: this.$t('labels.fleet.inviteUrls.expiresAfterOptions.30_minutes'),
      value: 30,
    },
    {
      name: this.$t('labels.fleet.inviteUrls.expiresAfterOptions.1_hour'),
      value: 60,
    },
    {
      name: this.$t('labels.fleet.inviteUrls.expiresAfterOptions.6_hours'),
      value: 6 * 60,
    },
    {
      name: this.$t('labels.fleet.inviteUrls.expiresAfterOptions.12_hours'),
      value: 12 * 60,
    },
    {
      name: this.$t('labels.fleet.inviteUrls.expiresAfterOptions.1_day'),
      value: 24 * 60,
    },
    {
      name: this.$t('labels.fleet.inviteUrls.expiresAfterOptions.7_days'),
      value: 24 * 60 * 7,
    },
  ]

  limitOptions = [
    {
      name: this.$t('labels.fleet.inviteUrls.limitOptions.infinite'),
      value: null,
    },
    {
      name: this.$t('labels.fleet.inviteUrls.limitOptions.1'),
      value: 1,
    },
    {
      name: this.$t('labels.fleet.inviteUrls.limitOptions.5'),
      value: 5,
    },
    {
      name: this.$t('labels.fleet.inviteUrls.limitOptions.10'),
      value: 10,
    },
    {
      name: this.$t('labels.fleet.inviteUrls.limitOptions.25'),
      value: 25,
    },
    {
      name: this.$t('labels.fleet.inviteUrls.limitOptions.50'),
      value: 50,
    },
    {
      name: this.$t('labels.fleet.inviteUrls.limitOptions.100'),
      value: 100,
    },
  ]

  get inviteUrls() {
    return this.collection.records
  }

  mounted() {
    this.fetch()
    this.setupForm()
  }

  setupForm() {
    this.form = {
      expiresAfterMinutes: null,
      limit: null,
      fleetSlug: this.fleet.slug,
    }
  }

  async fetch() {
    await this.collection.findAll({
      fleetSlug: this.fleet.slug,
    })
  }

  async create() {
    await this.collection.create(this.form, true)
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

  usesLeft(inviteUrl) {
    if (!inviteUrl.limit && inviteUrl.limit !== 0) {
      return this.$t('labels.fleet.inviteUrls.noLimit')
    }

    return this.$t('labels.fleet.inviteUrls.usesLeft', {
      count: inviteUrl.limit,
    })
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
@import '~stylesheets/variables';

.invite-url {
  margin-bottom: 20px;

  .invite-url-main {
    display: flex;
    align-content: center;
    justify-content: space-between;
    margin-bottom: 10px;

    .url-input {
      margin-right: 10px;
    }
  }

  .invite-url-subline {
    display: flex;
    align-content: center;
    justify-content: space-between;
    margin-bottom: 15px;
    padding: 0 10px;
    color: darken($text-color, 10%);
    font-size: 90%;
  }
}
</style>
