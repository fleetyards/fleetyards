<template>
  <section class="container signup">
    <div class="row">
      <div v-if="form" class="col-12">
        <ValidationObserver ref="form" v-slot="{ handleSubmit }" :slim="true">
          <form @submit.prevent="handleSubmit(signup)">
            <h1>
              <router-link to="/" :exact="true">
                {{ $t('app') }}
              </router-link>
            </h1>
            <ValidationProvider
              v-slot="{ errors }"
              vid="username"
              rules="required|alpha_dash|usernameTaken"
              :name="$t('labels.username')"
              :slim="true"
            >
              <FormInput
                id="username"
                v-model="form.username"
                :error="errors[0]"
                :hide-label-on-empty="true"
                :autofocus="true"
              />
            </ValidationProvider>
            <ValidationProvider
              v-slot="{ errors }"
              vid="email"
              rules="required|email"
              :name="$t('labels.email')"
              :slim="true"
            >
              <FormInput
                id="email"
                v-model="form.email"
                :error="errors[0]"
                :hide-label-on-empty="true"
              />
            </ValidationProvider>
            <ValidationProvider
              v-slot="{ errors }"
              vid="password"
              rules="required|min:8"
              :name="$t('labels.password')"
              :slim="true"
            >
              <FormInput
                id="password"
                v-model="form.password"
                :error="errors[0]"
                type="password"
                :hide-label-on-empty="true"
              />
            </ValidationProvider>
            <ValidationProvider
              v-slot="{ errors }"
              vid="passwordConfirmation"
              rules="required|confirmed:password"
              :name="$t('labels.passwordConfirmation')"
              :slim="true"
            >
              <FormInput
                id="passwordConfirmation"
                v-model="form.passwordConfirmation"
                :error="errors[0]"
                type="password"
                :hide-label-on-empty="true"
              />
            </ValidationProvider>

            <FormInput
              v-if="fleetInviteToken"
              id="fleetInviteToken"
              v-model="form.fleetInviteToken"
              :disabled="true"
              :hide-label-on-empty="true"
              :clearable="true"
              @clear="resetFleetInviteToken"
            />

            <Checkbox
              id="saleNotify"
              v-model="form.saleNotify"
              :label="$t('labels.user.saleNotify')"
            />

            <Btn
              :loading="submitting"
              type="submit"
              data-test="submit-signup"
              size="large"
              :block="true"
            >
              {{ $t('actions.signUp') }}
            </Btn>

            <p class="privacy-info">
              {{ $t('labels.signup.privacyPolicy') }}
              <router-link :to="{ name: 'privacy-policy' }">
                {{ $t('labels.privacyPolicy') }}
              </router-link>
            </p>

            <footer>
              <p class="text-center">
                {{ $t('labels.alreadyRegistered') }}
              </p>

              <Btn :to="{ name: 'login' }" size="small" :block="true">
                {{ $t('actions.login') }}
              </Btn>
            </footer>
          </form>
        </ValidationObserver>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter, Action } from 'vuex-class'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FormInput from 'frontend/core/components/Form/FormInput'
import Btn from 'frontend/core/components/Btn'
import Checkbox from 'frontend/core/components/Form/Checkbox'
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'

@Component<Signup>({
  components: {
    FormInput,
    Btn,
    Checkbox,
  },
  mixins: [MetaInfo],
})
export default class Signup extends Vue {
  @Getter('inviteToken', { namespace: 'fleet' }) fleetInviteToken

  @Action('resetInviteToken', { namespace: 'fleet' }) resetFleetInviteToken: any

  form: SignupForm | null = null

  submitting: boolean = false

  mounted() {
    this.setupForm()
  }

  setupForm() {
    this.form = {
      username: null,
      email: null,
      saleNotify: false,
      password: null,
      passwordConfirmation: null,
      fleetInviteToken: this.fleetInviteToken,
    }
  }

  async signup() {
    this.submitting = true

    const response = await this.$api.post('users/signup', this.form)

    this.submitting = false

    if (!response.error) {
      displaySuccess({
        text: this.$t('messages.signup.success'),
      })

      this.resetFleetInviteToken()

      // eslint-disable-next-line @typescript-eslint/no-empty-function
      this.$router.push('/').catch(() => {})
    } else if (
      response.error.response &&
      response.error.response.data &&
      response.error.response.data.code === 'blocked'
    ) {
      displayAlert({
        text: this.$t('texts.signup.blocked'),
      })
    } else {
      const { error } = response
      if (error.response && error.response.data) {
        const { data: errorData } = error.response

        this.$refs.form.setErrors(errorData.errors)

        displayAlert({
          text: errorData.message,
        })
      } else {
        displayAlert({
          text: this.$t('messages.signup.failure'),
        })
      }
    }
  }
}
</script>

<style lang="scss">
@import 'index';
</style>
