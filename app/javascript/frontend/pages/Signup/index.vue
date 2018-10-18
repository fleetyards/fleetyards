<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <form @submit.prevent="signup">
          <h1>
            <router-link
              to="/"
              exact>
              {{ t('app') }}
            </router-link>
          </h1>
          <div
            :class="{'has-error has-feedback': errors.has('username')}"
            class="form-group"
          >
            <transition name="fade">
              <label
                v-show="form.username"
                for="username"
              >
                {{ t('labels.username') }}
              </label>
            </transition>
            <input
              v-tooltip.right="errors.first('username')"
              v-validate="'required|alpha_dash|usernameTaken'"
              id="username"
              v-model="form.username"
              :data-vv-as="t('labels.username')"
              :placeholder="t('labels.username')"
              name="username"
              type="text"
              class="form-control"
              autofocus
            >
            <span
              v-show="errors.has('username')"
              class="form-control-feedback"
            >
              <i
                :title="errors.first('username')"
                class="fal fa-exclamation-triangle"
              />
            </span>
          </div>
          <div
            :class="{'has-error has-feedback': errors.has('rsiHandle')}"
            class="form-group"
          >
            <transition name="fade">
              <label
                v-show="form.rsiHandle"
                for="rsiHandle"
              >
                {{ t('labels.rsiHandle') }}
              </label>
            </transition>
            <input
              v-tooltip.right="errors.first('rsiHandle')"
              v-validate="'alpha_dash|handle'"
              id="rsi-handle"
              v-model="form.rsiHandle"
              :placeholder="t('labels.rsiHandle')"
              :data-vv-as="t('labels.rsiHandle')"
              name="rsiHandle"
              type="text"
              class="form-control"
            >
            <span
              v-show="errors.has('rsiHandle')"
              class="form-control-feedback"
            >
              <i
                :title="errors.first('rsiHandle')"
                class="fal fa-exclamation-triangle"
              />
            </span>
          </div>
          <div
            :class="{'has-error has-feedback': errors.has('email')}"
            class="form-group"
          >
            <transition name="fade">
              <label
                v-show="form.email"
                for="email"
              >
                {{ t('labels.email') }}
              </label>
            </transition>
            <input
              v-tooltip.right="errors.first('email')"
              v-validate="'required|email|emailTaken'"
              id="email"
              v-model="form.email"
              :data-vv-as="t('labels.email')"
              :placeholder="t('labels.email')"
              name="email"
              type="email"
              class="form-control"
            >
            <span
              v-show="errors.has('email')"
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
              :placeholder="t('labels.password')"
              :data-vv-as="t('labels.password')"
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
          <Checkbox
            id="saleNotify"
            v-model="form.saleNotify"
            :label="t('labels.user.saleNotify')"
          />
          <submit-button
            :loading="submitting"
            class="btn-block"
          >
            {{ t('actions.signUp') }}
          </submit-button>
          <p class="privacy-info">
            By creating a FleetYards account, you agree to our
            <router-link
              :to="{name: 'privacy-policy'}"
            >
              Privacy Policy
            </router-link>
          </p>
          <div class="clearfix"/>
          <br>
          <br>
          <p class="text-center">{{ t('labels.alreadyRegistered') }}</p>
          <InternalLink
            :route="{name: 'login'}"
            block
            small
          >
            {{ t('actions.login') }}
          </InternalLink>
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
import InternalLink from 'frontend/components/InternalLink'
import Checkbox from 'frontend/components/Form/Checkbox'

export default {
  components: {
    SubmitButton,
    InternalLink,
    Checkbox,
  },
  mixins: [I18n, MetaInfo],
  data() {
    return {
      submitting: false,
      form: {
        username: null,
        rsiHandle: null,
        email: null,
        saleNotify: false,
        password: null,
        passwordConfirmation: null,
      },
    }
  },
  methods: {
    async signup() {
      const result = await this.$validator.validateAll()
      if (!result) {
        return
      }
      this.submitting = true
      const response = await this.$api.post('users/signup', this.form)
      this.submitting = false
      if (!response.error) {
        success(this.t('messages.signup.success'))
        this.$router.push('/')
      } else if (response.error.response && response.error.response.data && response.error.response.data.code === 'blacklisted') {
        alert(this.t('texts.signup.blacklisted'))
      }
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.signUp'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
