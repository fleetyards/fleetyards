<template>
  <ValidationObserver v-slot="{ handleSubmit }" slim>
    <form @submit.prevent="handleSubmit(changePassword)">
      <div class="row">
        <div class="col-lg-12">
          <h1>{{ $t('headlines.changePassword') }}</h1>
        </div>
      </div>
      <div class="row">
        <div class="col-lg-12 col-xl-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="currentPassword"
            rules="required"
            :name="$t('labels.currentPassword')"
            slim
          >
            <FormInput
              v-if="isAuthenticated"
              id="currentPassword"
              v-model="form.currentPassword"
              :error="errors[0]"
              type="password"
              :clearable="true"
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
              :clearable="true"
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
              :clearable="true"
            />
          </ValidationProvider>
          <br />
          <Btn :loading="submitting" type="submit" size="large">
            {{ $t('actions.save') }}
          </Btn>
        </div>
      </div>
    </form>
  </ValidationObserver>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import FormInput from 'frontend/components/Form/FormInput'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'

export default {
  name: 'ChangePassword',

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

  methods: {
    async changePassword() {
      this.submitting = true

      const response = await this.$api.put('password/update', this.form)

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

<style lang="scss" scoped>
@import 'index';
</style>
