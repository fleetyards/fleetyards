<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <form @submit.prevent="signup">
          <h1>
            <router-link
              to="/"
              exact
            >
              {{ $t('app') }}
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
                {{ $t('labels.username') }}
              </label>
            </transition>
            <input
              id="username"
              v-model="form.username"
              v-tooltip.right="errors.first('username')"
              v-validate="'required|alpha_dash|usernameTaken'"
              data-test="username"
              :data-vv-as="$t('labels.username')"
              :placeholder="$t('labels.username')"
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
                {{ $t('labels.rsiHandle') }}
              </label>
            </transition>
            <input
              id="rsiHandle"
              v-model="form.rsiHandle"
              v-tooltip.right="errors.first('rsiHandle')"
              v-validate="'alpha_dash|handle'"
              data-test="rsi-handle"
              :placeholder="$t('labels.rsiHandle')"
              :data-vv-as="$t('labels.rsiHandle')"
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
                {{ $t('labels.email') }}
              </label>
            </transition>
            <input
              id="email"
              v-model="form.email"
              v-tooltip.right="errors.first('email')"
              v-validate="'required|email'"
              data-test="email"
              :data-vv-as="$t('labels.email')"
              :placeholder="$t('labels.email')"
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
                {{ $t('labels.password') }}
              </label>
            </transition>
            <input
              id="password"
              ref="password"
              v-model="form.password"
              v-tooltip.right="errors.first('password')"
              v-validate="'required|min:8'"
              data-test="password"
              :placeholder="$t('labels.password')"
              :data-vv-as="$t('labels.password')"
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
                {{ $t('labels.passwordConfirmation') }}
              </label>
            </transition>
            <input
              id="password-confirmation"
              v-model="form.passwordConfirmation"
              v-tooltip.right="errors.first('passwordConfirmation')"
              v-validate="'required|confirmed:password'"
              data-test="password-confirmation"
              :data-vv-as="$t('labels.passwordConfirmation')"
              :placeholder="$t('labels.passwordConfirmation')"
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
            :label="$t('labels.user.saleNotify')"
          />

          <Btn
            :loading="submitting"
            type="submit"
            size="large"
            block
          >
            {{ $t('actions.signUp') }}
          </Btn>

          <p class="privacy-info">
            By creating a FleetYards account, you agree to our
            <router-link
              :to="{name: 'privacy-policy'}"
            >
              Privacy Policy
            </router-link>
          </p>

          <footer>
            <p class="text-center">
              {{ $t('labels.alreadyRegistered') }}
            </p>

            <Btn
              :to="{name: 'login'}"
              size="small"
              block
            >
              {{ $t('actions.login') }}
            </Btn>
          </footer>
        </form>
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/components/Btn'
import Checkbox from 'frontend/components/Form/Checkbox'

export default {
  name: 'Signup',

  components: {
    Btn,
    Checkbox,
  },

  mixins: [
    MetaInfo,
  ],

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
        this.$alert({
          text: this.$t('messages.signup.invalid'),
        })
        return
      }

      this.submitting = true
      const response = await this.$api.post('users/signup', this.form)
      this.submitting = false

      if (!response.error) {
        this.$success({
          text: this.$t('messages.signup.success'),
        })
        this.$router.push('/')
      } else if (response.error.response && response.error.response.data && response.error.response.data.code === 'blacklisted') {
        this.$alert({
          text: this.$t('texts.signup.blacklisted'),
        })
      } else {
        const { error } = response
        if (error.response && error.response.data) {
          const { data } = error.response

          data.errors.map(item => ({
            field: item[0],
            errors: item[1],
          })).forEach((item) => {
            item.errors.forEach(errorItem => this.errors.add({
              field: item.field,
              msg: errorItem,
            }))
          })

          this.$alert({
            text: data.message,
          })
        } else {
          this.$alert({
            text: this.$t('messages.signup.failure'),
          })
        }
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
