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
            v-if="rsiVerificationDisabled"
            class="disabled"
          >
            <a>
              {{ t('labels.rsiVerifiedLong') }}
              <span class="verified">
                <i class="fa fa-check" />
              </span>
            </a>
          </li>
          <router-link
            v-else
            :to="{ name: 'settings-verify' }"
            tag="li"
          >
            <a>{{ t('actions.startRsiVerification') }}</a>
          </router-link>
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
  </section>
</template>

<script>
import { mapGetters } from 'vuex'
import I18n from 'frontend/mixins/I18n'

export default {
  mixins: [I18n],
  data() {
    return {
      rsiVerificationToken: null,
    }
  },
  computed: {
    ...mapGetters([
      'currentUser',
    ]),
    rsiVerificationDisabled() {
      return this.currentUser.rsiVerified
    },
  },
}
</script>
