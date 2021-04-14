<template>
  <SecurePage class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <h1>{{ $t('headlines.settings.account') }}</h1>
        </div>
      </div>

      <div class="row">
        <div class="col-12">
          <ValidationObserver
            v-if="form"
            v-slot="{ handleSubmit }"
            :slim="true"
          >
            <form @submit.prevent="handleSubmit(updateAccount)">
              <div class="row">
                <div class="col-12 col-md-6">
                  <ValidationProvider
                    v-slot="{ errors }"
                    vid="username"
                    rules="required|alpha_dash"
                    :name="$t('labels.username')"
                    :slim="true"
                  >
                    <FormInput
                      id="username"
                      v-model="form.username"
                      :error="errors[0]"
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
                      type="email"
                    />
                  </ValidationProvider>

                  <FormInput
                    v-if="currentUser.unconfirmedEmail"
                    id="unconfirmedEmail"
                    v-model="currentUser.unconfirmedEmail"
                    type="email"
                    :disabled="true"
                    :label="$t('labels.user.unconfirmedEmail')"
                    :no-placeholder="true"
                  />
                  <Btn :loading="submitting" type="submit" size="large">
                    {{ $t('actions.save') }}
                  </Btn>
                </div>
              </div>
            </form>
          </ValidationObserver>
        </div>
      </div>

      <hr />

      <div class="row">
        <div class="col-12">
          <br />
          <p>
            {{ $t('labels.account.destroyInfo') }}
          </p>
          <Btn
            :loading="deleting"
            variant="danger"
            size="large"
            data-test="destroy-account"
            @click.native="destroy"
          >
            {{ $t('actions.destroyAccount') }}
          </Btn>
        </div>
      </div>
    </div>
  </SecurePage>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import { displaySuccess, displayAlert, displayConfirm } from 'frontend/lib/Noty'
import SecurePage from 'frontend/core/components/SecurePage'
import Btn from 'frontend/core/components/Btn'
import FormInput from 'frontend/core/components/Form/FormInput'
import MetaInfo from 'frontend/mixins/MetaInfo'
import userCollection from 'frontend/api/collections/User'

@Component<SettingsAccount>({
  components: {
    SecurePage,
    Btn,
    FormInput,
  },
  mixins: [MetaInfo],
})
export default class SettingsAccount extends Vue {
  @Getter('currentUser', { namespace: 'session' }) currentUser

  form: UserAccountForm | null = null

  deleting: boolean = false

  submitting: boolean = false

  created() {
    if (this.currentUser) {
      this.setupForm()
    }
  }

  @Watch('currentUser')
  onCurrentUserChange() {
    this.setupForm()
  }

  setupForm() {
    this.form = {
      username: this.currentUser.username,
      email: this.currentUser.email,
    }
  }

  async updateAccount() {
    this.submitting = true

    const response = await userCollection.updateAccount(this.form)

    this.submitting = false

    if (!response.error) {
      this.$comlink.$emit('user-update')

      displaySuccess({
        text: this.$t('messages.updateAccount.success'),
      })
    }
  }

  async destroy() {
    this.deleting = true
    displayConfirm({
      text: this.$t('messages.confirm.account.destroy'),
      onConfirm: async () => {
        const response = await userCollection.destroy()

        this.deleting = false

        if (!response.error) {
          displaySuccess({
            text: this.$t('messages.account.destroy.success'),
          })

          await this.$store.dispatch('session/logout')

          // eslint-disable-next-line @typescript-eslint/no-empty-function
          this.$router.push({ name: 'home' }).catch(() => {})
        } else {
          displayAlert({
            text: this.$t('messages.account.destroy.error'),
          })
        }
      },
      onClose: () => {
        this.deleting = false
      },
    })
  }
}
</script>
