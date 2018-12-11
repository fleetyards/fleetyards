<template>
  <form @submit.prevent="changePassword">
    <div class="row">
      <div class="col-md-12">
        <h1>{{ t('headlines.changePassword') }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-md-12 col-lg-6">
        <div
          v-if="$store.getters.isAuthenticated"
          :class="{'has-error has-feedback': errors.has('currentPassword')}"
          class="form-group"
        >
          <label for="current-password">{{ t('labels.currentPassword') }}</label>
          <input
            v-tooltip.right="errors.first('currentPassword')"
            v-validate="'required'"
            id="current-password"
            v-model="form.currentPassword"
            :data-vv-as="t('labels.currentPassword')"
            :placeholder="t('labels.currentPassword')"
            name="currentPassword"
            type="password"
            class="form-control"
            autofocus
          >
          <span
            v-show="errors.has('currentPassword')"
            class="form-control-feedback"
          >
            <i class="fal fa-exclamation-triangle" />
          </span>
        </div>
        <div
          :class="{'has-error has-feedback': errors.has('password')}"
          class="form-group"
        >
          <label for="password">{{ t('labels.password') }}</label>
          <input
            v-tooltip.right="errors.first('password')"
            v-validate="'required|min:8'"
            id="password"
            ref="password"
            v-model="form.password"
            :autofocus="!$store.getters.isAuthenticated"
            :data-vv-as="t('labels.password')"
            :placeholder="t('labels.password')"
            name="password"
            type="password"
            class="form-control"
          >
          <span
            v-show="errors.has('password')"
            class="form-control-feedback"
          >
            <i class="fal fa-exclamation-triangle" />
          </span>
        </div>
        <div
          :class="{'has-error has-feedback': errors.has('passwordConfirmation')}"
          class="form-group"
        >
          <label for="password-confirmation">{{ t('labels.passwordConfirmation') }}</label>
          <input
            v-tooltip.right="errors.first('passwordConfirmation')"
            v-validate="'required|confirmed:password'"
            id="password-confirmation"
            v-model="form.passwordConfirmation"
            :data-vv-as="t('labels.passwordConfirmation')"
            :placeholder="t('labels.passwordConfirmation')"
            name="passwordConfirmation"
            type="password"
            class="form-control"
          >
          <span
            v-show="errors.has('passwordConfirmation')"
            class="form-control-feedback"
          >
            <i class="fal fa-exclamation-triangle" />
          </span>
        </div>
        <br>
        <submit-button :loading="submitting">
          {{ t('actions.save') }}
        </submit-button>
      </div>
    </div>
  </form>
</template>

<script>
import { success, alert } from 'frontend/lib/Noty'
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import SubmitButton from 'frontend/components/SubmitButton'

export default {
  components: {
    SubmitButton,
  },
  mixins: [I18n, MetaInfo],
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
  methods: {
    async changePassword() {
      const result = await this.$validator.validateAll()
      if (!result) {
        return
      }
      this.submitting = true
      const response = await this.$api.put('password/update', this.form)
      this.submitting = false
      if (!response.error) {
        success(this.t('messages.changePassword.success'))
        this.$router.push('/')
      } else {
        alert(this.t('messages.changePassword.failure'))
      }
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.changePassword'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
