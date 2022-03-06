<template>
  <section class="container login">
    <div class="row">
      <div v-if="form" class="col-12">
        <ValidationObserver ref="form" v-slot="{ handleSubmit }" :small="true">
          <form @submit.prevent="handleSubmit(login)">
            <h1>
              <router-link to="/" exact>
                {{ $t('app') }}
              </router-link>
            </h1>
            <template v-if="twoFactorRequired">
              <ValidationProvider
                v-slot="{ errors }"
                vid="twoFactorCode"
                rules="required"
                :name="$t('labels.twoFactorCode')"
                :slim="true"
              >
                <FormInput
                  id="twoFactorCode"
                  v-model="form.twoFactorCode"
                  :error="errors[0]"
                  :autofocus="true"
                  :hide-label-on-empty="true"
                  :clearable="true"
                />
              </ValidationProvider>
            </template>
            <div v-show="!twoFactorRequired">
              <ValidationProvider
                v-slot="{ errors }"
                vid="login"
                rules="required"
                :name="$t('labels.login')"
                :slim="true"
              >
                <FormInput
                  id="login"
                  v-model="form.login"
                  :error="errors[0]"
                  :autofocus="true"
                  :hide-label-on-empty="true"
                  :clearable="true"
                />
              </ValidationProvider>

              <ValidationProvider
                v-slot="{ errors }"
                vid="password"
                rules="required"
                :name="$t('labels.password')"
                :slim="true"
              >
                <FormInput
                  id="password"
                  v-model="form.password"
                  :error="errors[0]"
                  type="password"
                  :hide-label-on-empty="true"
                  :clearable="true"
                />
              </ValidationProvider>
              <Checkbox
                id="rememberMe"
                v-model="form.rememberMe"
                :label="$t('labels.rememberMe')"
              />
            </div>
            <Btn
              :loading="submitting"
              type="submit"
              data-test="submit-login"
              size="large"
              :block="true"
            >
              {{ $t('actions.login') }}
            </Btn>
            <Btn
              :to="{
                name: 'request-password',
              }"
              variant="link"
              size="small"
              :block="true"
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
                :block="true"
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
import Btn from '@/frontend/core/components/Btn/index.vue'
import FormInput from '@/frontend/core/components/Form/FormInput/index.vue'
import Checkbox from '@/frontend/core/components/Form/Checkbox/index.vue'
import MetaInfo from '@/frontend/mixins/MetaInfo'
import { displayAlert } from '@/frontend/lib/Noty'
import sessionCollection from '@/frontend/api/collections/Session'

export default {
  name: 'LoginPage',

  components: {
    Btn,
    Checkbox,
    FormInput,
  },

  mixins: [MetaInfo],

  data() {
    return {
      form: null,
      submitting: false,
      twoFactorRequired: false,
    }
  },

  mounted() {
    this.setupForm()
  },

  methods: {
    async login() {
      this.submitting = true

      const response = await sessionCollection.create(this.form)

      this.submitting = false

      if (
        response.error &&
        response.error.response?.data?.code ===
          'session.create.two_factor_required'
      ) {
        this.twoFactorRequired = true
      } else if (!response.error) {
        await this.$store.dispatch('session/login')
        if (this.$route.params.redirectToRoute) {
          await this.$router.replace({
            name: this.$route.params.redirectToRoute,
          })
        } else {
          await this.$router.push('/').catch(() => {})
        }
      } else {
        displayAlert({
          text: response.error.response.data.message,
        })
      }
    },

    setupForm() {
      this.form = {
        login: null,
        password: null,
        rememberMe: false,
        twoFactorCode: null,
      }
    },
  },
}
</script>

<style lang="scss">
@import 'index.scss';
</style>
