<template>
  <section class="container change-password">
    <div class="row">
      <div class="col-12">
        <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
          <form @submit.prevent="handleSubmit(changePassword)">
            <h1>
              <router-link :to="{ name: 'home' }" exact>
                {{ $t('app') }}
              </router-link>
            </h1>
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
                :autofocus="true"
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

            <Btn :loading="submitting" type="submit" size="large" :block="true">
              {{ $t('actions.save') }}
            </Btn>

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

<script>
import FormInput from 'frontend/core/components/Form/FormInput'
import Btn from 'frontend/core/components/Btn'
import MetaInfo from 'frontend/mixins/MetaInfo'
import { mapGetters } from 'vuex'
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'

export default {
  components: {
    FormInput,
    Btn,
  },

  mixins: [MetaInfo],

  data() {
    return {
      submitting: false,
      form: {
        currentPassword: null,
        password: null,
        passwordConfirmation: null,
      },
    }
  },

  computed: {
    ...mapGetters('session', ['isAuthenticated']),
  },

  mounted() {
    if (this.isAuthenticated) {
      this.$router.push({ name: 'settings-change-password' }).catch(() => {})
    }
  },

  methods: {
    async changePassword() {
      this.submitting = true

      const response = await this.$api.put(
        `password/update/${this.$route.params.token}`,
        this.form,
      )

      this.submitting = false

      if (!response.error) {
        displaySuccess({
          text: this.$t('messages.changePassword.success'),
        })

        this.$router.push('/')
      } else {
        displayAlert({
          text: this.$t('messages.changePassword.failure'),
        })
      }
    },
  },
}
</script>

<style lang="scss">
@import 'index';
</style>
