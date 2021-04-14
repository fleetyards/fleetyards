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

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import SecurePage from 'frontend/core/components/SecurePage'
import Btn from 'frontend/core/components/Btn'
import FormInput from 'frontend/core/components/Form/FormInput'
import MetaInfo from 'frontend/mixins/MetaInfo'
import { enabledRouteGuard } from 'frontend/utils/RouteGuards/TwoFactor'
import twoFactorCollection from 'frontend/api/collections/TwoFactor'
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'

@Component<TwoFactorDisable>({
  beforeRouteEnter: enabledRouteGuard,
  components: {
    SecurePage,
    Btn,
    FormInput,
  },
  mixins: [MetaInfo],
})
export default class TwoFactorDisable extends Vue {
  @Getter('currentUser', { namespace: 'session' }) currentUser

  submitting: boolean = false

  form: TwoFactorForm | null = null

  mounted() {
    this.setupForm()
  }

  setupForm() {
    this.form = {
      twoFactorCode: null,
    }
  }

  async disable() {
    this.submitting = true

    const response = await twoFactorCollection.disable(this.form.twoFactorCode)

    this.submitting = false

    this.setupForm()

    if (!response.error) {
      this.$comlink.$emit('user-update')

      displaySuccess({
        text: this.$t('messages.twoFactor.disable.success'),
      })

      this.$router
        .push({ name: 'settings-security', hash: '#two-factor' })
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        .catch(() => {})
    } else if (response.error === 'requires_access_confirmation') {
      this.$comlink.$emit('access-confirmation-required')
    } else {
      displayAlert({
        text: this.$t('messages.twoFactor.disable.failure'),
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

.two-factor-form-inner {
  display: flex;
  flex-direction: column;
}
</style>
