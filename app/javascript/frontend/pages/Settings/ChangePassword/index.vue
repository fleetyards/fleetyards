<template>
  <form @submit.prevent="changePassword">
    <div class="row">
      <div class="col-md-12">
        <h1>{{ $t('headlines.changePassword') }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-md-12 col-lg-6">
        <div
          v-if="isAuthenticated"
          :class="{'has-error has-feedback': errors.has('currentPassword')}"
          class="form-group"
        >
          <label for="current-password">
            {{ $t('labels.currentPassword') }}
          </label>
          <input
            id="current-password"
            v-model="form.currentPassword"
            v-tooltip.right="errors.first('currentPassword')"
            v-validate="'required'"
            :data-vv-as="$t('labels.currentPassword')"
            :placeholder="$t('labels.currentPassword')"
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
          <label for="password">
            {{ $t('labels.password') }}
          </label>
          <input
            id="password"
            ref="password"
            v-model="form.password"
            v-tooltip.right="errors.first('password')"
            v-validate="'required|min:8'"
            :autofocus="!isAuthenticated"
            :data-vv-as="$t('labels.password')"
            :placeholder="$t('labels.password')"
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
          <label for="password-confirmation">
            {{ $t('labels.passwordConfirmation') }}
          </label>
          <input
            id="password-confirmation"
            v-model="form.passwordConfirmation"
            v-tooltip.right="errors.first('passwordConfirmation')"
            v-validate="'required|confirmed:password'"
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
        <br>
        <Btn
          :loading="submitting"
          type="submit"
          size="large"
        >
          {{ $t('actions.save') }}
        </Btn>
      </div>
    </div>
  </form>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'

export default {
  components: {
    Btn,
  },
  mixins: [MetaInfo],
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
        this.$success({
          text: this.$t('messages.changePassword.success'),
        })
        this.$router.push('/')
      } else {
        this.$alert({
          text: this.$t('messages.changePassword.failure'),
        })
      }
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.$t('title.changePassword'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import './styles/index';
</style>
