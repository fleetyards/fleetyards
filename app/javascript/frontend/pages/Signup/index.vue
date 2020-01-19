<template>
  <section class="container signup">
    <div class="row">
      <div class="col-xs-12">
        <ValidationObserver
          ref="form"
          v-slot="{ handleSubmit }"
          small
        >
          <form @submit.prevent="handleSubmit(signup)">
            <h1>
              <router-link
                to="/"
                exact
              >
                {{ $t('app') }}
              </router-link>
            </h1>
            <ValidationProvider
              v-slot="{ errors }"
              vid="username"
              rules="required|alpha_dash|usernameTaken"
              :name="$t('labels.username')"
              slim
            >
              <FormInput
                id="username"
                v-model="form.username"
                :error="errors[0]"
                autofocus
                hide-label-on-empty
              />
            </ValidationProvider>
            <ValidationProvider
              v-slot="{ errors }"
              vid="email"
              rules="required|email"
              :name="$t('labels.email')"
              slim
            >
              <FormInput
                id="email"
                v-model="form.email"
                :error="errors[0]"
                autofocus
                hide-label-on-empty
              />
            </ValidationProvider>
            <ValidationProvider
              v-slot="{ errors }"
              vid="password"
              rules="required|min:8"
              :name="$t('labels.password')"
              slim
            >
              <FormInput
                id="password"
                v-model="form.password"
                :error="errors[0]"
                type="password"
                autofocus
                hide-label-on-empty
              />
            </ValidationProvider>
            <ValidationProvider
              v-slot="{ errors }"
              vid="passwordConfirmation"
              rules="required|confirmed:password"
              :name="$t('labels.passwordConfirmation')"
              slim
            >
              <FormInput
                id="passwordConfirmation"
                v-model="form.passwordConfirmation"
                :error="errors[0]"
                type="password"
                autofocus
                hide-label-on-empty
              />
            </ValidationProvider>

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
              block
            >
              {{ $t('actions.signUp') }}
            </Btn>

            <p class="privacy-info">
              {{ $t('labels.signup.privacyPolicy') }}
              <router-link
                :to="{name: 'privacy-policy'}"
              >
                {{ $t('labels.privacyPolicy') }}
              </router-link>
            </p>

            <footer>
              <p class="text-center">
                {{ $t('labels.alreadyRegistered') }}
              </p>

              <Btn
                :to="{name: 'login'}"
                size="small"
                block
              >
                {{ $t('actions.login') }}
              </Btn>
            </footer>
          </form>
        </ValidationObserver>
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import FormInput from 'frontend/components/Form/FormInput'
import Btn from 'frontend/components/Btn'
import Checkbox from 'frontend/components/Form/Checkbox'

export default {
  name: 'Signup',

  components: {
    FormInput,
    Btn,
    Checkbox,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      submitting: false,
      form: {
        username: null,
        email: null,
        saleNotify: false,
        password: null,
        passwordConfirmation: null,
      },
    }
  },

  methods: {
    async signup() {
      this.submitting = true

      const response = await this.$api.post('users/signup', this.form)

      this.submitting = false

      if (!response.error) {
        this.$success({
          text: this.$t('messages.signup.success'),
        })
        this.$router.push('/')
      } else if (response.error.response && response.error.response.data && response.error.response.data.code === 'blacklisted') {
        this.$alert({
          text: this.$t('texts.signup.blacklisted'),
        })
      } else {
        const { error } = response
        if (error.response && error.response.data) {
          const { data: errorData } = error.response

          this.$refs.form.setErrors(errorData.errors)

          this.$alert({
            text: errorData.message,
          })
        } else {
          this.$alert({
            text: this.$t('messages.signup.failure'),
          })
        }
      }
    },
  },
}
</script>

<style lang="scss">
  @import 'index';
</style>
