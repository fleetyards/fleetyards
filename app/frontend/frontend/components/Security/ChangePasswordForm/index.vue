<template>
  <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
    <form v-if="form" @submit.prevent="handleSubmit(changePassword)">
      <ValidationProvider
        v-slot="{ errors }"
        vid="currentPassword"
        rules="required"
        :name="$t('labels.currentPassword')"
        :slim="true"
      >
        <FormInput
          id="currentPassword"
          v-model="form.currentPassword"
          :error="errors[0]"
          type="password"
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
        />
      </ValidationProvider>
      <div class="d-flex">
        <Btn :loading="submitting" type="submit">
          {{ $t('actions.updatePassword') }}
        </Btn>
        <Btn :to="{ name: 'request-password' }" variant="link">
          {{ $t('actions.reset-password') }}
        </Btn>
      </div>
    </form>
  </ValidationObserver>
</template>

<script>
import FormInput from '@/frontend/core/components/Form/FormInput/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import { displaySuccess, displayAlert } from '@/frontend/lib/Noty'

export default {
  name: 'ChangePasswordForm',

  components: {
    Btn,
    FormInput,
  },

  data() {
    return {
      form: null,
      submitting: false,
    }
  },

  mounted() {
    this.setupForm()
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

        this.$router.push('/').catch(() => {})
      } else {
        displayAlert({
          text: this.$t('messages.changePassword.failure'),
        })
      }
    },

    setupForm() {
      this.form = {
        currentPassword: null,
        password: null,
        passwordConfirmation: null,
      }
    },
  },
}
</script>
