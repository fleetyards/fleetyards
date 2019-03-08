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
              {{ t('app') }}
            </router-link>
          </h1>
          <div class="form-group">
            <input
              v-model="form.login"
              data-test="login"
              :placeholder="t('labels.login')"
              type="text"
              autofocus
              class="form-control"
            >
          </div>
          <div class="form-group">
            <input
              v-model="form.password"
              data-test="password"
              :placeholder="t('labels.password')"
              type="password"
              class="form-control"
            >
          </div>
          <Checkbox
            id="rememberMe"
            v-model="form.rememberMe"
            :label="t('labels.rememberMe')"
          />
          <submit-button
            :loading="submitting"
            class="btn-block"
          >
            {{ t('actions.login') }}
          </submit-button>
          <div class="clearfix" />
          <br>
          <br>
          <div class="text-center">
            <router-link
              class="btn btn-link"
              to="/password/request"
            >
              {{ t('actions.reset-password') }}
            </router-link>
          </div>
          <br>
          <br>
          <p class="text-center">
            {{ t('labels.signUp') }}
          </p>
          <InternalLink
            :route="{name: 'signup'}"
            block
            small
          >
            {{ t('actions.signUp') }}
          </InternalLink>
        </form>
      </div>
    </div>
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import { alert } from 'frontend/lib/Noty'
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
        this.$store.dispatch('login', response.data)
        if (this.$route.params.redirectToRoute) {
          this.$router.replace({ name: this.$route.params.redirectToRoute })
        } else {
          this.$router.push('/')
        }
      } else {
        alert(response.error.response.data.message)
      }
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.login'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
