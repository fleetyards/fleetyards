<template>
  <div class="row">
    <div v-if="currentUser" class="col-12">
      <div class="row">
        <div class="col-12">
          <h1>{{ $t('headlines.settings.security.index') }}</h1>
        </div>
      </div>
      <br />
      <div class="row">
        <div class="col-12 col-md-6">
          <h2 id="change-password">{{ $t('headlines.changePassword') }}</h2>
          <ChangePasswordForm />
        </div>
      </div>

      <hr />

      <div class="row">
        <div class="col-12 col-md-6">
          <h2 id="two-factor">
            {{ $t('headlines.settings.security.twoFactor') }}
            <small>
              <span
                v-if="currentUser.twoFactorRequired"
                class="badge badge-success"
              >
                <i class="fas fa-check" />
                {{ $t('labels.enabled') }}
              </span>
              <span v-else class="badge badge-danger">
                <i class="fas fa-times" />
                {{ $t('labels.disabled') }}
              </span>
            </small>
          </h2>
          <div class="two-factor-actions">
            <template v-if="currentUser.twoFactorRequired">
              <Btn :to="{ name: 'settings-two-factor-disable' }">
                {{ $t('actions.twoFactor.disable') }}
              </Btn>
              <Btn @click.native="generateBackupCodes">
                {{ $t('actions.twoFactor.generateBackupCodes') }}
              </Btn>
            </template>
            <Btn v-else :to="{ name: 'settings-two-factor-enable' }">
              {{ $t('actions.twoFactor.enable') }}
            </Btn>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import Btn from '@/frontend/core/components/Btn/index.vue'
import ChangePasswordForm from '@/frontend/components/Security/ChangePasswordForm/index.vue'
import MetaInfo from '@/frontend/mixins/MetaInfo'
import { displayConfirm } from '@/frontend/lib/Noty'

export default {
  name: 'SettingsSecurityStatus',

  components: {
    Btn,
    ChangePasswordForm,
  },

  mixins: [MetaInfo],

  computed: {
    ...mapGetters('session', ['currentUser']),
  },

  methods: {
    generateBackupCodes() {
      this.backupCodesWaiting = true

      displayConfirm({
        text: this.$t('messages.confirm.twoFactor.generateBackupCodes'),
        onConfirm: () => {
          this.backupCodesWaiting = false
          this.$router
            .push({ name: 'settings-two-factor-backup-codes' })
            .catch(() => {})
        },
        onClose: () => {
          this.backupCodesWaiting = false
          this.deleting = false
        },
      })
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index.scss';
</style>
