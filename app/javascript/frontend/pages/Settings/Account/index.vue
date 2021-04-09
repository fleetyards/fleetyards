<template>
  <section>
    <div class="row">
      <div class="col-12">
        <h1>{{ $t('headlines.settings.account') }}</h1>
      </div>
    </div>

    <!-- <div class="row">
      <div class="col-12">
        <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
          <form @submit.prevent="handleSubmit(submit)">
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
              </div>
              <div class="col-12 col-md-6">
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
              </div>
            </div>
          </form>
        </ValidationObserver>
      </div>
    </div> -->

    <div class="row">
      <div class="col-12">
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
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/core/components/Btn'
import { displaySuccess, displayAlert, displayConfirm } from 'frontend/lib/Noty'

export default {
  name: 'SettingsAccount',

  components: {
    Btn,
  },

  mixins: [MetaInfo],

  data() {
    return {
      deleting: false,
    }
  },

  methods: {
    async destroy() {
      this.deleting = true
      displayConfirm({
        text: this.$t('messages.confirm.account.destroy'),
        onConfirm: async () => {
          const response = await this.$api.destroy('users/current')
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
            this.deleting = false
          }
        },
        onClose: () => {
          this.deleting = false
        },
      })
    },
  },
}
</script>
