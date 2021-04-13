<template>
  <SecurePage class="row">
    <div v-if="currentUser" class="col-12">
      <div class="row">
        <div class="col-12">
          <h1>{{ $t('headlines.settings.twoFactor.backupCodes') }}</h1>
        </div>
      </div>
      <div v-if="backupCodes" class="row two-factor-backup-codes">
        <div class="col-12 col-md-6 offset-md-3">
          <BackupCodesPanel :codes="backupCodes" />
          <Btn
            :to="{ name: 'settings-security', hash: '#two-factor' }"
            :exact="true"
          >
            {{ $t('actions.done') }}
          </Btn>
        </div>
      </div>
    </div>
  </SecurePage>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import SecurePage from 'frontend/core/components/SecurePage'
import Btn from 'frontend/core/components/Btn'
import BackupCodesPanel from 'frontend/components/Security/TwoFactorBackupCodesPanel'
import MetaInfo from 'frontend/mixins/MetaInfo'
import { enabledRouteGuard } from 'frontend/utils/RouteGuards/TwoFactor'
import twoFactorCollection from 'frontend/api/collections/TwoFactor'
import { displayAlert } from 'frontend/lib/Noty'

@Component<TwoFactorBackupCodes>({
  beforeRouteEnter: enabledRouteGuard,
  components: {
    SecurePage,
    Btn,
    BackupCodesPanel,
  },
  mixins: [MetaInfo],
})
export default class TwoFactorBackupCodes extends Vue {
  @Getter('currentUser', { namespace: 'session' }) currentUser

  submitting: boolean = false

  backupCodes: string[] | null = null

  mounted() {
    this.$comlink.$on('access-confirmed', this.generateBackupCodes)
  }

  beforeDestroy() {
    this.$comlink.$off('access-confirmed')
  }

  async generateBackupCodes() {
    this.submitting = true

    const response = await twoFactorCollection.generateBackupCodes()

    this.submitting = false

    if (!response.error) {
      this.backupCodes = response.data.codes
    } else if (response.error === 'requires_access_confirmation') {
      this.$comlink.$emit('access-confirmation-required')
    } else {
      displayAlert({
        text: this.$t('messages.twoFactor.backupCodes.failure'),
      })
    }
  }
}
</script>

<style lang="scss">
.two-factor-backup-codes-action {
  margin: 40px 0;
}
</style>
