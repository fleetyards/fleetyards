<template>
  <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
    <form @submit.prevent="handleSubmit(submit)">
      <div class="row">
        <div class="col-lg-12">
          <h1>{{ $t('headlines.settings.notifications') }}</h1>
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="saleNotify"
            :name="$t('labels.user.saleNotify')"
            :slim="true"
          >
            <Checkbox
              id="saleNotify"
              v-model="form.saleNotify"
              :label="$t('labels.user.saleNotify')"
              :class="{ 'has-error has-feedback': errors[0] }"
            />
          </ValidationProvider>
        </div>
      </div>
      <br />
      <Btn :loading="submitting" type="submit" size="large">
        {{ $t('actions.save') }}
      </Btn>
    </form>
  </ValidationObserver>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import { displaySuccess } from 'frontend/lib/Noty'
import Btn from 'frontend/core/components/Btn'
import Checkbox from 'frontend/core/components/Form/Checkbox'
import MetaInfo from 'frontend/mixins/MetaInfo'
import userCollection from 'frontend/api/collections/User'

@Component<SettingsNotifications>({
  components: {
    Btn,
    Checkbox,
  },
  mixins: [MetaInfo],
})
export default class SettingsNotifications extends Vue {
  @Getter('currentUser', { namespace: 'session' }) currentUser

  form: NotificationSettingsForm = null

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
      saleNotify: this.currentUser.saleNotify,
    }
  }

  async submit() {
    this.submitting = true

    const response = await userCollection.updateAccount(this.form)

    this.submitting = false

    if (!response.error) {
      this.$comlink.$emit('user-update')

      displaySuccess({
        text: this.$t('messages.updateNotifications.success'),
      })
    }
  }
}
</script>
