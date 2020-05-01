<template>
  <section class="container login">
    <div class="row">
      <div class="col-xs-12">
        <ValidationObserver ref="form" v-slot="{ handleSubmit }" small>
          <form @submit.prevent="handleSubmit(login)">
            <h1>
              <router-link to="/" exact>
                {{ $t('app') }}
              </router-link>
            </h1>
            <ValidationProvider
              v-slot="{ errors }"
              vid="login"
              rules="required"
              :name="$t('labels.login')"
              slim
            >
              <FormInput
                id="login"
                v-model="form.login"
                :error="errors[0]"
                autofocus
                hide-label-on-empty
                clearable
              />
            </ValidationProvider>

            <ValidationProvider
              v-slot="{ errors }"
              vid="password"
              rules="required"
              :name="$t('labels.password')"
              slim
            >
              <FormInput
                id="password"
                v-model="form.password"
                :error="errors[0]"
                type="password"
                hide-label-on-empty
                clearable
              />
            </ValidationProvider>
            <Checkbox
              id="rememberMe"
              v-model="form.rememberMe"
              :label="$t('labels.rememberMe')"
            />
            <Btn
              :loading="submitting"
              type="submit"
              data-test="submit-login"
              size="large"
              block
            >
              {{ $t('actions.login') }}
            </Btn>
            <Btn
              :to="{
                name: 'request-password',
              }"
              variant="link"
              size="small"
              block
            >
              {{ $t('actions.reset-password') }}
            </Btn>
            <footer>
              <p class="text-center">
                {{ $t('labels.signup.link') }}
              </p>
              <Btn
                data-test="signup-link"
                :to="{ name: 'signup' }"
                size="small"
                block
              >
                {{ $t('actions.signUp') }}
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
import Btn from 'frontend/components/Btn'
import FormInput from 'frontend/components/Form/FormInput'
import Checkbox from 'frontend/components/Form/Checkbox'

export default {
  name: 'Login',

  components: {
    Btn,
    FormInput,
    Checkbox,
  },

  mixins: [MetaInfo],

  data() {
    return {
      submitting: false,
      form: {
        rememberMe: false,
        password: null,
        login: null,
      },
    }
  },

  methods: {
    async login() {
      this.submitting = true
      const response = await this.$api.post('sessions', this.form)
      this.submitting = false

      if (!response.error) {
        await this.$store.dispatch('session/login', response.data)
        if (this.$route.params.redirectToRoute) {
          await this.$router.replace({
            name: this.$route.params.redirectToRoute,
          })
        } else {
          await this.$router.push('/')
        }
      } else {
        this.$alert({
          text: response.error.response.data.message,
        })
      }
    },
  },
}
</script>

<style lang="scss">
@import 'index';
</style>
