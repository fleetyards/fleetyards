<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12 col-sm-3 col-sm-push-9">
        <ul class="tabs">
          <router-link
            :to="{ name: 'settings-profile' }"
            tag="li"
          >
            <a>{{ t('nav.profile') }}</a>
          </router-link>
          <router-link
            :to="{ name: 'settings-account' }"
            tag="li"
          >
            <a>{{ t('nav.account') }}</a>
          </router-link>
          <li
            v-if="currentUser && currentUser.rsiHandle"
            :class="{
              disabled: rsiVerificationDisabled,
            }"
          >
            <a @click="startRsiVerification">
              <template v-if="currentUser.rsiVerified">
                {{ t('labels.rsiVerifiedLong') }}
                <span class="verified">
                  <i class="fa fa-check" />
                </span>
              </template>
              <template v-else>
                {{ t('actions.startRsiVerification') }}
              </template>
            </a>
          </li>
          <router-link
            :to="{ name: 'settings-change-password' }"
            tag="li"
          >
            <a>{{ t('actions.changePassword') }}</a>
          </router-link>
        </ul>
      </div>
      <div class="col-xs-12 col-sm-9 col-sm-pull-3">
        <router-view />
      </div>
    </div>
    <RsiVerificationModal
      ref="rsiVerificationModal"
      :verification-text="verificationText"
      :on-close="onRsiVerificationModalClose"
    />
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
import I18n from 'frontend/mixins/I18n'
import RsiVerificationModal from 'frontend/partials/RsiVerificationModal'

export default {
  components: {
    RsiVerificationModal,
  },
  mixins: [I18n],
  data() {
    return {
      fetchRsiVerificationToken: false,
      rsiVerificationToken: null,
    }
  },
  computed: {
    ...mapGetters([
      'currentUser',
    ]),
    rsiVerificationDisabled() {
      return this.fetchRsiVerificationToken || this.currentUser.rsiVerified
    },
    verificationText() {
      if (!this.currentUser) {
        return ''
      }
      return this.t('texts.rsiVerification.verificationText', { username: this.currentUser.username, token: this.rsiVerificationToken })
    },
  },
  methods: {
    startRsiVerification() {
      if (this.rsiVerificationDisabled) {
        return
      }
      this.fetchRsiVerificationToken = true
      this.$api.post('users/start-rsi-verification', {}, ({ error, data }) => {
        this.fetchRsiVerificationToken = false
        if (!error) {
          this.rsiVerificationToken = data.token
          this.$refs.rsiVerificationModal.open()
        }
      })
    },
    onRsiVerificationModalClose() {
      this.$comlink.$emit('userUpdate')
    },
  },
}
</script>
