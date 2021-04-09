<template>
  <SecurePage class="row">
    <div v-if="currentUser" class="col-12">
      <div class="row">
        <div class="col-12">
          <h1>{{ $t('headlines.settings.twoFactor.enable') }}</h1>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
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

          <template v-else-if="!currentUser.twoFactorRequired">
            <p>
              {{ $t('texts.twoFactor.enable') }}
            </p>
            <ValidationObserver
              v-if="form"
              v-slot="{ handleSubmit }"
              :slim="true"
            >
              <form
                class="two-factor-form"
                @submit.prevent="handleSubmit(enable)"
              >
                <div class="row">
                  <div class="col-12 two-factor-form-inner">
                    <div class="two-factor-qrcode">
                      <img
                        :src="currentUser.twoFactorQrCodeUrl"
                        alt="two-factor-qrcode"
                      />
                    </div>
                    <ValidationProvider
                      vid="twoFactorCode"
                      rules="required"
                      :name="$t('labels.twoFactorCode')"
                      :slim="true"
                    >
                      <FormInput
                        id="twoFactorCode"
                        v-model="form.twoFactorCode"
                        class="two-factor-input"
                        :autofocus="true"
                        :no-label="true"
                        translation-key="twoFactorCode"
                      />
                    </ValidationProvider>

                    <br />

                    <Btn
                      :loading="submitting"
                      type="submit"
                      size="large"
                      :block="true"
                    >
                      {{ $t('actions.twoFactor.enable') }}
                    </Btn>
                  </div>
                </div>
              </form>
            </ValidationObserver>
          </template>
        </div>
      </div>
    </div>
  </SecurePage>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import { disabledRouteGuard } from 'frontend/utils/RouteGuards/TwoFactor'
import twoFactorCollection from 'frontend/api/collections/TwoFactor'
import MetaInfo from 'frontend/mixins/MetaInfo'
import SecurePage from 'frontend/core/components/SecurePage'
import BackupCodesPanel from 'frontend/components/Security/TwoFactorBackupCodesPanel'
import FormInput from 'frontend/core/components/Form/FormInput'
import Btn from 'frontend/core/components/Btn'
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'

@Component<TwoFactorEnable>({
  beforeRouteEnter: disabledRouteGuard,
  components: {
    SecurePage,
    BackupCodesPanel,
    FormInput,
    Btn,
  },
  mixins: [MetaInfo],
})
export default class TwoFactorEnable extends Vue {
  @Getter('currentUser', { namespace: 'session' }) currentUser

  submitting: boolean = false

  backupCodes: string[] | null = null

  form: TwoFactorForm | null = null

  mounted() {
    this.setupForm()
  }

  setupForm() {
    this.form = {
      twoFactorCode: null,
    }
  }

  async enable() {
    this.submitting = true

    const response = await twoFactorCollection.enable(this.form.twoFactorCode)

    this.submitting = false

    this.setupForm()

    if (!response.error) {
      this.$comlink.$emit('user-update')

      this.backupCodes = response.data.codes

      displaySuccess({
        text: this.$t('messages.twoFactor.enable.success'),
      })
    } else if (response.error === 'requires_access_confirmation') {
      this.$comlink.$emit('access-confirmation-required')
    } else {
      displayAlert({
        text: this.$t('messages.twoFactor.enable.failure'),
      })
    }
  }
}
</script>

<style lang="scss" scoped>
.two-factor-form {
  display: flex;
  justify-content: center;
  margin: 40px 0;

  .two-factor-form-inner {
    width: 300px;
  }
}

.two-factor-qrcode {
  margin-bottom: 20px;
  text-align: center;

  img {
    max-width: 250px;
  }
}
</style>
