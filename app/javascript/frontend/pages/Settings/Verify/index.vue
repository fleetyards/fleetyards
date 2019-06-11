<template>
  <form @submit.prevent="submit">
    <div class="row">
      <div class="col-md-12">
        <h1>{{ $t('headlines.verify') }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-xs-10">
        <br>
        <p v-html="$t('texts.rsiVerification.instructions')" />
        <br>
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
              @click.native="copyToken"
            >
              <i class="fa fa-copy" />
            </Btn>
          </div>
        </div>
      </div>
      <Loader
        :loading="submitting"
        fixed
      />
    </div>
    <br>
    <Btn
      :loading="fetchRsiVerificationToken || submitting"
      type="submit"
      size="large"
    >
      {{ $t('actions.verify') }}
    </Btn>
    <br>
    <p v-html="$t('texts.rsiVerification.subline')" />
  </form>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/components/Btn'
import Loader from 'frontend/components/Loader'
import { mapGetters } from 'vuex'

export default {
  components: {
    Loader,
    Btn,
  },
  mixins: [MetaInfo],
  data() {
    return {
      submitting: false,
      fetchRsiVerificationToken: false,
      rsiVerificationToken: null,
    }
  },
  computed: {
    ...mapGetters('session', [
      'currentUser',
      'citizen',
    ]),
    verificationText() {
      if (!this.currentUser || !this.rsiVerificationToken) {
        return ''
      }
      return this.$t('texts.rsiVerification.verificationText', { username: this.currentUser.username, token: this.rsiVerificationToken })
    },
  },
  watch: {
    currentUser: 'checkVerification',
  },
  mounted() {
    this.checkVerification()
  },
  methods: {
    checkVerification() {
      if (this.currentUser && this.currentUser.rsiVerified) {
        this.$router.push({ name: 'settings-profile' })
      } else {
        this.startRsiVerification()
      }
    },
    copyToken() {
      this.$copyText(this.verificationText).then(() => {
        this.$success(this.$t('messages.copy.success'))
      }, () => {
        this.$alert(this.$t('messages.copy.failure'))
      })
    },
    async submit() {
      this.submitting = true
      const response = await this.$api.post('users/finish-rsi-verification')
      this.submitting = false
      if (!response.error) {
        this.$success(this.$t('messages.rsiVerification.success'))
        this.$comlink.$emit('userUpdate')
        this.$router.push({ name: 'settings-profile' })
      } else {
        this.$alert(this.$t('messages.rsiVerification.failure'))
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
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.$t('title.verify'),
    })
  },
}
</script>
