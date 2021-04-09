<template>
  <ValidationObserver v-slot="{ handleSubmit }" slim>
    <form v-if="form" @submit.prevent="handleSubmit(changePassword)">
      <ValidationProvider
        v-slot="{ errors }"
        vid="currentPassword"
        rules="required"
        :name="$t('labels.currentPassword')"
        slim
      >
        <FormInput
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

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import FormInput from 'frontend/core/components/Form/FormInput'
import Btn from 'frontend/core/components/Btn'
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'

@Component<ChangePasswordForm>({
  components: {
    FormInput,
    Btn,
  },
})
export default class ChangePasswordForm extends Vue {
  submitting: boolean = false

  form: ChangePasswordForm | null = null

  mounted() {
    this.setupForm()
  }

  setupForm() {
    this.form = {
      currentPassword: null,
      password: null,
      passwordConfirmation: null,
    }
  }

  async changePassword() {
    this.submitting = true

    const response = await this.$api.put('password/update', this.form)

    this.submitting = false

    if (!response.error) {
      displaySuccess({
        text: this.$t('messages.changePassword.success'),
      })

      // eslint-disable-next-line @typescript-eslint/no-empty-function
      this.$router.push('/').catch(() => {})
    } else {
      displayAlert({
        text: this.$t('messages.changePassword.failure'),
      })
    }
  }
}
</script>
