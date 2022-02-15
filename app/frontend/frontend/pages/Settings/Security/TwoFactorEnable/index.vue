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

<script>
import { mapGetters } from 'vuex'
import SecurePage from '@/frontend/core/components/SecurePage/index.vue'
import BackupCodesPanel from '@/frontend/components/Security/TwoFactorBackupCodesPanel/index.vue'
import FormInput from '@/frontend/core/components/Form/FormInput/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import MetaInfo from '@/frontend/mixins/MetaInfo'
import twoFactorCollection from '@/frontend/api/collections/TwoFactor'
import { disabledRouteGuard } from '@/frontend/utils/RouteGuards/TwoFactor'
import { displaySuccess, displayAlert } from '@/frontend/lib/Noty'

export default {
  name: 'TwoFactorEnable',

  components: {
    SecurePage,
    BackupCodesPanel,
    FormInput,
    Btn,
  },

  mixins: [MetaInfo],

  beforeRouteEnter: disabledRouteGuard,

  data() {
    return {
      submitting: false,
      backupCodes: null,
      form: null,
    }
  },

  computed: {
    ...mapGetters('session', ['currentUser']),
  },

  mounted() {
    this.setupForm()
  },

  methods: {
    setupForm() {
      this.form = {
        twoFactorCode: null,
      }
    },

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
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index.scss';
</style>
