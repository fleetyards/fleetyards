<template>
  <section class="container request-password">
    <div class="row">
      <div class="col-12">
        <ValidationObserver v-slot="{ handleSubmit }" slim>
          <form @submit.prevent="handleSubmit(requestPassword)">
            <h1>
              <router-link to="/" exact>
                {{ $t('app') }}
              </router-link>
            </h1>

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
                type="email"
                :hide-label-on-empty="true"
                :autofocus="true"
              />
            </ValidationProvider>

            <Btn :loading="submitting" type="submit" size="large" :block="true">
              {{ $t('actions.requestPassword') }}
            </Btn>

            <footer v-if="!isAuthenticated">
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
import { Getter } from 'vuex-class'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FormInput from 'frontend/core/components/Form/FormInput'
import Btn from 'frontend/core/components/Btn'
import { displaySuccess } from 'frontend/lib/Noty'

@Component<RequestPassword>({
  components: {
    FormInput,
    Btn,
  },
  mixins: [MetaInfo],
})
export default class RequestPassword extends Vue {
  @Getter('isAuthenticated', { namespace: 'session' }) isAuthenticated: boolean

  submitting: boolean = false

  form: RequestPasswordForm | null = null

  mounted() {
    this.setupForm()
  }

  setupForm() {
    this.form = {
      email: null,
    }
  }

  async requestPassword() {
    this.submitting = true

    await this.$api.post('password/request', this.form)

    this.submitting = false

    displaySuccess({
      text: this.$t('messages.requestPasswordChange.success'),
    })

    // eslint-disable-next-line @typescript-eslint/no-empty-function
    this.$router.push('/').catch(() => {})
  }
}
</script>

<style lang="scss">
@import 'index';
</style>
