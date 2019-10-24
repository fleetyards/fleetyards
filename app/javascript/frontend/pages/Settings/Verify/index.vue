<template>
  <div class="row">
    <div class="col-xs-12">
      <div class="row">
        <div class="col-xs-12">
          <h1>{{ $t('headlines.settings.verify') }}</h1>
        </div>
      </div>
      <div class="row">
        <div class="col-xs-12 col-md-push-2 col-md-8">
          <form @submit.prevent="saveHandle">
            <div class="row">
              <div class="col-xs-12">
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
            </div>
            <div class="row">
              <div class="col-xs-12">
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
                  <Panel
                    v-else-if="!loading"
                    for-text
                  >
                    <div class="text-center">
                      {{ $t('labels.blank.rsiCitizen') }}
                    </div>
                  </Panel>
                </transition>
              </div>
            </div>
            <div class="row">
              <div class="col-xs-12">
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
          <form
            v-if="!currentUser.rsiVerified"
            @submit.prevent="verify"
          >
            <div class="row">
              <div class="col-xs-12">
                <hr>
                <p v-html="$t('texts.rsiVerification.instructions')" />
                <br>
                <Panel
                  v-if="verificationDisabled"
                  for-text
                >
                  <div class="text-warning text-center">
                    {{ rsiHandleMandatory }}
                  </div>
                </Panel>
                <div
                  :class="{'has-error has-feedback': errors.has('username')}"
                  class="form-group"
                >
                  <div class="input-group-flex">
                    <input
                      :value="verificationText"
                      class="form-control text-center disabled-clean"
                      disabled
                    >
                    <Btn
                      size="small"
                      :disabled="verificationDisabled"
                      @click.native="copyToken"
                    >
                      <i class="fa fa-copy" />
                    </Btn>
                  </div>
                </div>
                <Loader
                  :loading="submitting"
                  fixed
                />
                <br>
                <div class="text-center">
                  <Btn
                    :loading="fetchRsiVerificationToken || verifying"
                    type="submit"
                    size="large"
                    :disabled="verificationDisabled"
                  >
                    {{ $t('actions.verify') }}
                  </Btn>
                </div>
                <br>
                <p>{{ $t('texts.rsiVerification.subline') }}</p>
              </div>
            </div>
          </form>
          <div
            v-else
            class="row"
          >
            <div class="col-xs-12">
              <Panel
                variant="success"
                for-text
              >
                <div class="text-center">
                  {{ $t('labels.rsiVerifiedLong') }}
                  <i class="fa fa-check-circle" />
                </div>
              </Panel>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/components/Btn'
import Loader from 'frontend/components/Loader'
import Panel from 'frontend/components/Panel'
import { mapGetters } from 'vuex'

export default {
  name: 'Verify',

  components: {
    Loader,
    Btn,
    Panel,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      form: {
        rsiHandle: null,
      },
      loading: false,
      rsiCitizen: null,
      rsiFetchTimeout: null,
      submitting: false,
      verifying: false,
      fetchRsiVerificationToken: false,
      rsiVerificationToken: null,
    }
  },

  computed: {
    ...mapGetters('session', [
      'currentUser',
      'citizen',
    ]),

    verificationDisabled() {
      return !this.citizen || !this.currentUser.rsiHandle
    },

    rsiHandleMandatory() {
      if (!this.verificationDisabled) {
        return null
      }

      return this.$t('messages.rsiVerification.rsiHandleMandatory')
    },

    verificationText() {
      if (!this.currentUser || !this.rsiVerificationToken) {
        return ''
      }
      return this.$t('texts.rsiVerification.verificationText', { username: this.currentUser.username, token: this.rsiVerificationToken })
    },
  },

  watch: {
    currentUser() {
      this.checkVerification()
      this.setupForm()
    },

    citizen() {
      this.rsiCitizen = this.citizen
    },
  },

  mounted() {
    this.checkVerification()
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
    },

    checkVerification() {
      if (this.currentUser && !this.currentUser.rsiVerified && this.currentUser.rsiHandle) {
        this.startRsiVerification()
      }
    },

    copyToken() {
      this.$copyText(this.verificationText).then(() => {
        this.$confirm({
          text: this.$t('messages.rsiVerification.copySuccess'),
          onConfirm: async () => {
            window.open('https://robertsspaceindustries.com/account/profile', '_blank')
          },
          confirmBtnLayout: 'default',
        })
      }, () => {
        this.$alert({
          text: this.$t('messages.copy.failure'),
        })
      })
    },

    async verify() {
      this.verifying = true

      const response = await this.$api.post('users/finish-rsi-verification')

      this.verifying = false

      if (!response.error) {
        this.$success({
          text: this.$t('messages.rsiVerification.success'),
        })

        this.$comlink.$emit('userUpdate')
      } else {
        this.$alert({
          text: this.$t('messages.rsiVerification.failure'),
        })
      }
    },

    async saveHandle() {
      this.submitting = true

      const response = await this.$api.put('users/current', this.form)

      this.submitting = false

      if (!response.error) {
        this.$success({
          text: this.$t('messages.rsiVerification.saveHandleSuccess'),
        })

        this.$comlink.$emit('userUpdate')
      }
    },

    async startRsiVerification() {
      this.fetchRsiVerificationToken = true

      const response = await this.$api.post('users/start-rsi-verification', {})

      this.fetchRsiVerificationToken = false

      if (!response.error) {
        this.rsiVerificationToken = response.data.token
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
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
