<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <form @submit.prevent="login">
          <h1>
            <router-link
              to="/"
              exact
            >
              {{ $t('app') }}
            </router-link>
          </h1>
          <div class="form-group">
            <input
              v-model="form.login"
              data-test="login"
              :placeholder="$t('labels.login')"
              type="text"
              autofocus
              class="form-control"
            >
          </div>
          <div class="form-group">
            <input
              v-model="form.password"
              data-test="password"
              :placeholder="$t('labels.password')"
              type="password"
              class="form-control"
            >
          </div>
          <Checkbox
            id="rememberMe"
            v-model="form.rememberMe"
            :label="$t('labels.rememberMe')"
          />
          <Btn
            :loading="submitting"
            type="submit"
            size="large"
            block
          >
            {{ $t('actions.login') }}
          </Btn>
          <Btn
            :to="{
              name: 'request-password',
            }"
            variant="link"
            size="small"
            block
          >
            {{ $t('actions.reset-password') }}
          </Btn>
          <footer>
            <p class="text-center">
              {{ $t('labels.signUp') }}
            </p>
            <Btn
              data-test="signup-link"
              :to="{name: 'signup'}"
              size="small"
              block
            >
              {{ $t('actions.signUp') }}
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
  name: 'Login',

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
        rememberMe: false,
        password: null,
        login: null,
      },
    }
  },

  methods: {
    async login() {
      this.submitting = true
      const response = await this.$api.post('sessions', this.form)
      this.submitting = false

      if (!response.error) {
        this.$store.dispatch('session/login', response.data)
        if (this.$route.params.redirectToRoute) {
          this.$router.replace({ name: this.$route.params.redirectToRoute })
        } else {
          this.$router.push('/')
        }
      } else {
        this.$alert({
          text: response.error.response.data.message,
        })
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
