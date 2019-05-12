<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <form @submit.prevent="changePassword">
          <h1>
            <router-link
              :to="{ name: 'home'}"
              exact
            >
              {{ t('app') }}
            </router-link>
          </h1>
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
              id="password"
              ref="password"
              v-model="form.password"
              v-tooltip.right="errors.first('password')"
              v-validate="'required|min:8'"
              :data-vv-as="t('labels.password')"
              :placeholder="t('labels.password')"
              name="password"
              type="password"
              class="form-control"
              autofocus
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
              id="password-confirmation"
              v-model="form.passwordConfirmation"
              v-tooltip.right="errors.first('passwordConfirmation')"
              v-validate="'required|confirmed:password'"
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

          <Btn
            :loading="submitting"
            type="submit"
            size="large"
            block
          >
            {{ t('actions.save') }}
          </Btn>

          <footer>
            <p class="text-center">
              {{ t('labels.alreadyRegistered') }}
            </p>

            <Btn
              :to="{name: 'login'}"
              size="small"
              block
            >
              {{ t('actions.login') }}
            </Btn>
          </footer>
        </form>
      </div>
    </div>
  </section>
</template>

<script>
import { success, alert } from 'frontend/lib/Noty'
import Btn from 'frontend/components/Btn'
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import { mapGetters } from 'vuex'

export default {
  components: {
    Btn,
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
  computed: {
    ...mapGetters('session', [
      'isAuthenticated',
    ]),
  },
  mounted() {
    if (this.isAuthenticated) {
      this.$router.push({ name: 'settings-change-password' })
    }
  },
  methods: {
    async changePassword() {
      const result = await this.$validator.validateAll()
      if (!result) {
        return
      }
      this.submitting = true
      const response = await this.$api.put(`password/update/${this.$route.params.token}`, this.form)
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
  @import './styles/index';
</style>
