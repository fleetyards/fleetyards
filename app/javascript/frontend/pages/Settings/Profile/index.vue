<template>
  <form @submit.prevent="submit">
    <div class="row">
      <div class="col-md-12">
        <h1>{{ $t('headlines.settings.profile') }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-md-12 col-lg-6">
        <div
          :class="{'has-error has-feedback': errors.has('username')}"
          class="form-group"
        >
          <label for="username">
            {{ $t('labels.username') }}
          </label>
          <input
            id="username"
            v-model="form.username"
            v-tooltip.bottom-end="errors.first('username')"
            v-validate="'required|alpha_dash'"
            data-test="username"
            :data-vv-as="$t('labels.username')"
            :placeholder="$t('labels.username')"
            name="username"
            type="text"
            class="form-control"
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
          :class="{'has-error has-feedback': errors.has('email')}"
          class="form-group"
        >
          <label for="email">
            {{ $t('labels.email') }}
          </label>
          <input
            id="email"
            v-model="form.email"
            v-tooltip.bottom-end="errors.first('email')"
            v-validate="'required|email'"
            data-test="email"
            :data-vv-as="$t('labels.email')"
            name="email"
            type="email"
            class="form-control"
          >
          <span
            v-show="errors.has('email')"
            class="form-control-feedback"
          >
            <i
              :title="errors.first('email')"
              class="fal fa-exclamation-triangle"
            />
          </span>
        </div>
      </div>
    </div>
    <br>
    <Btn
      :loading="submitting"
      type="submit"
      size="large"
    >
      {{ $t('actions.save') }}
    </Btn>
  </form>
</template>

<script>
import { mapGetters } from 'vuex'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/components/Btn'

export default {
  name: 'Profile',

  components: {
    Btn,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      form: {
        username: null,
        email: null,
      },
      submitting: false,
    }
  },

  computed: {
    ...mapGetters('session', [
      'currentUser',
      'citizen',
    ]),
  },

  watch: {
    currentUser: 'setupForm',
  },

  created() {
    if (this.currentUser) {
      this.setupForm()
    }
  },

  methods: {
    setupForm() {
      this.form.username = this.currentUser.username
      this.form.email = this.currentUser.email
    },

    async submit() {
      const result = await this.$validator.validateAll()

      if (!result) {
        return
      }

      this.submitting = true

      const response = await this.$api.put('users/current', this.form)

      this.submitting = false

      if (!response.error) {
        this.$comlink.$emit('userUpdate')

        this.$success({
          text: this.$t('messages.updateProfile.success'),
        })
      }
    },
  },
}
</script>
