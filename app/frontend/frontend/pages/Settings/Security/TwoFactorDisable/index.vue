<template>
  <SecurePage class="row">
    <div v-if="currentUser" class="col-12">
      <div class="row">
        <div class="col-12">
          <h1>{{ $t('headlines.settings.twoFactor.disable') }}</h1>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <p class="text-center">
            {{ $t('texts.twoFactor.disable') }}
          </p>

          <ValidationObserver
            v-if="form"
            v-slot="{ handleSubmit }"
            :slim="true"
          >
            <form
              class="two-factor-form"
              @submit.prevent="handleSubmit(disable)"
            >
              <div class="row">
                <div class="col-12 two-factor-form-inner">
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

                  <Btn :loading="submitting" type="submit" size="large">
                    {{ $t('actions.twoFactor.disable') }}
                  </Btn>
                </div>
              </div>
            </form>
          </ValidationObserver>
        </div>
      </div>
    </div>
  </SecurePage>
</template>

<script>
import { mapGetters } from 'vuex'
import SecurePage from '@/frontend/core/components/SecurePage/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import FormInput from '@/frontend/core/components/Form/FormInput/index.vue'
import MetaInfo from '@/frontend/mixins/MetaInfo'
import twoFactorCollection from '@/frontend/api/collections/TwoFactor'
import { enabledRouteGuard } from '@/frontend/utils/RouteGuards/TwoFactor'
import { displaySuccess, displayAlert } from '@/frontend/lib/Noty'

export default {
  name: 'TwoFactorDisable',

  components: {
    Btn,
    FormInput,
    SecurePage,
  },

  mixins: [MetaInfo],

  beforeRouteEnter: enabledRouteGuard,

  data() {
    return {
      form: null,
      submitting: false,
    }
  },

  computed: {
    ...mapGetters('session', ['currentUser']),
  },

  mounted() {
    this.setupForm()
  },

  methods: {
    async disable() {
      this.submitting = true

      const response = await twoFactorCollection.disable(
        this.form.twoFactorCode
      )

      this.submitting = false

      this.setupForm()

      if (!response.error) {
        this.$comlink.$emit('user-update')

        displaySuccess({
          text: this.$t('messages.twoFactor.disable.success'),
        })

        this.$router
          .push({
            hash: '#two-factor',
            name: 'settings-security',
          })
          .catch(() => {})
      } else if (response.error === 'requires_access_confirmation') {
        this.$comlink.$emit('access-confirmation-required')
      } else {
        displayAlert({
          text: this.$t('messages.twoFactor.disable.failure'),
        })
      }
    },

    setupForm() {
      this.form = {
        twoFactorCode: null,
      }
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index.scss';
</style>
