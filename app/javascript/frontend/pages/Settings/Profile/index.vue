<template>
  <form @submit.prevent="submit">
    <div class="row">
      <div class="col-md-12">
        <h1>{{ $t('headlines.settings') }}</h1>
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
        <Checkbox
          id="saleNotify"
          v-model="form.saleNotify"
          :label="$t('labels.user.saleNotify')"
        />
        <Checkbox
          id="publicHangar"
          v-model="form.publicHangar"
          :label="$t('labels.user.publicHangar')"
        />
        <div
          :class="{'has-error has-feedback': errors.has('rsiHandle')}"
          class="form-group"
        >
          <label for="rsi-handle">
            {{ $t('labels.rsiHandle') }}
          </label>
          <div class="input-group">
            <span class="input-group-addon">
              https://robertsspaceindustries.com/citizens/
            </span>
            <input
              id="rsi-handle"
              v-model="form.rsiHandle"
              v-tooltip.bottom-end="errors.first('rsiHandle')"
              v-validate="'alpha_dash'"
              data-test="rsi-handle"
              :data-vv-as="$t('labels.rsiHandle')"
              name="rsiHandle"
              type="text"
              class="form-control"
              @input="changeHandle"
            >
          </div>
          <span
            v-show="errors.has('rsiHandle')"
            class="form-control-feedback"
          >
            <i
              :title="errors.first('handle')"
              class="fal fa-exclamation-triangle"
            />
          </span>
        </div>
      </div>
      <div class="col-md-12 col-lg-6">
        <Loader :loading="loading" />
        <transition name="fade">
          <Panel v-if="rsiCitizen">
            <table class="table table-striped">
              <tbody>
                <tr>
                  <td>
                    <strong>{{ $t('user.rsi.username') }}</strong>
                  </td>
                  <td>{{ rsiCitizen.username }}</td>
                </tr>
                <tr>
                  <td>
                    <strong>{{ $t('user.rsi.handle') }}</strong>
                  </td>
                  <td>{{ rsiCitizen.handle }}</td>
                </tr>
                <tr>
                  <td>
                    <strong>{{ $t('user.rsi.title') }}</strong>
                  </td>
                  <td>{{ rsiCitizen.title }}</td>
                </tr>
                <tr>
                  <td>
                    <strong>{{ $t('user.rsi.citizenRecord') }}</strong>
                  </td>
                  <td>{{ rsiCitizen.citizenRecord }}</td>
                </tr>
                <tr>
                  <td>
                    <strong>{{ $t('user.rsi.enlisted') }}</strong>
                  </td>
                  <td>{{ rsiCitizen.enlisted }}</td>
                </tr>
                <tr>
                  <td>
                    <strong>{{ $t('user.rsi.languages') }}</strong>
                  </td>
                  <td>{{ rsiCitizen.languages }}</td>
                </tr>
                <tr>
                  <td>
                    <strong>{{ $t('user.rsi.location') }}</strong>
                  </td>
                  <td>{{ rsiCitizen.location }}</td>
                </tr>
              </tbody>
            </table>
          </Panel>
          <Panel v-else-if="!loading">
            <div class="empty-citizen">
              {{ $t('labels.blank.rsiCitizen') }}
            </div>
          </Panel>
        </transition>
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
import Checkbox from 'frontend/components/Form/Checkbox'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'

export default {
  components: {
    Btn,
    Checkbox,
    Loader,
    Panel,
  },
  mixins: [MetaInfo],
  data() {
    return {
      form: {
        rsiHandle: null,
        username: null,
        email: null,
        saleNotify: false,
        publicHangar: true,
      },
      loading: false,
      rsiCitizen: null,
      rsiFetchTimeout: null,
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
    citizen() {
      this.rsiCitizen = this.citizen
    },
  },
  created() {
    if (this.currentUser) {
      this.setupForm()
    }
    if (this.citizen) {
      this.rsiCitizen = this.citizen
    }
  },
  methods: {
    changeHandle() {
      if (this.rsiFetchTimeout) {
        clearTimeout(this.rsiFetchTimeout)
      }
      this.rsiFetchTimeout = setTimeout(() => {
        this.fetchCitizen()
      }, 300)
    },
    setupForm() {
      this.form.rsiHandle = this.currentUser.rsiHandle
      this.form.username = this.currentUser.username
      this.form.email = this.currentUser.email
      this.form.saleNotify = !!this.currentUser.saleNotify
      this.form.publicHangar = !!this.currentUser.publicHangar
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
        this.$success(this.$t('messages.updateProfile.success'))
      }
    },
    async fetchCitizen() {
      this.rsiCitizen = null

      if (!this.form.rsiHandle) {
        return
      }

      this.loading = true
      const response = await this.$api.get(`rsi/citizens/${this.form.rsiHandle}`, {})
      this.loading = false
      if (!response.error) {
        this.rsiCitizen = response.data
      }
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.$t('title.settings'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import './styles/index';
</style>
