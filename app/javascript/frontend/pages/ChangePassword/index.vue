<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <form @submit.prevent="changePassword">
          <h1
            v-if="$store.getters.isAuthenticated"
            class="back-button"
          >
            {{ t('headlines.changePassword') }}
            <router-link
              v-tooltip.left="t('actions.back')"
              :to="{ name: 'settings'}"
              class="btn btn-link"
            >
              <i class="fal fa-chevron-left" />
            </router-link>
          </h1>
          <h1 v-else>
            <router-link
              :to="{ name: 'home'}"
              exact>
              {{ t('app') }}
            </router-link>
          </h1>
          <div
            v-if="$store.getters.isAuthenticated"
            :class="{'has-error has-feedback': errors.has('currentPassword')}"
            class="form-group"
          >
            <transition name="fade">
              <label
                v-show="form.currentPassword"
                for="current-password"
              >
                {{ t('labels.currentPassword') }}
              </label>
            </transition>
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
            <transition name="fade">
              <label
                v-show="form.password"
                for="password"
              >
                {{ t('labels.password') }}
              </label>
            </transition>
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
            <transition name="fade">
              <label
                v-show="form.passwordConfirmation"
                for="password-confirmation"
              >
                {{ t('labels.passwordConfirmation') }}
              </label>
            </transition>
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
          <submit-button
            :loading="submitting"
            class="btn-block"
          >
            {{ t('actions.save') }}
          </submit-button>
          <template v-if="!$store.getters.isAuthenticated">
            <div class="clearfix"/>
            <br>
            <br>
            <p class="text-center">{{ t('labels.alreadyRegistered') }}</p>
            <router-link
              class="btn btn-default btn-block"
              to="/login">
              {{ t('actions.login') }}
            </router-link>
          </template>
        </form>
      </div>
    </div>
  </section>
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
      const response = await this.$api.post(`password/update/${this.$route.params.token}`, this.form)
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
