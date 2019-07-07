<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12">
        <form @submit.prevent="requestPassword">
          <h1>
            <router-link
              to="/"
              exact
            >
              {{ $t('app') }}
            </router-link>
          </h1>
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
              :data-vv-as="$t('labels.email')"
              :placeholder="$t('labels.email')"
              name="email"
              type="email"
              class="form-control"
              autofocus
            >
            <span
              v-show="errors.has('email')"
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
            {{ $t('actions.requestPassword') }}
          </Btn>

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

export default {
  components: {
    Btn,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      submitting: false,
      form: {
        email: null,
      },
    }
  },

  methods: {
    async requestPassword() {
      const result = await this.$validator.validateAll()
      if (!result) {
        return
      }
      this.submitting = true
      await this.$api.post('password/request', this.form)
      this.submitting = false
      this.$success({
        text: this.$t('messages.requestPasswordChange.success'),
      })
      this.$router.push('/')
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
