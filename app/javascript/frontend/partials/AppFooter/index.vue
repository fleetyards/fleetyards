<template>
  <footer class="app-footer">
    <div class="app-footer-border app-footer-border-top">
      <div class="app-footer-border-left" />
      <div class="app-footer-border-right" />
    </div>
    <div class="app-footer-inner">
      <div class="app-footer-inner-border app-footer-inner-border-top">
        <div class="app-footer-inner-border-bg" />
      </div>
      <div class="app-footer-item">
        <a
          v-tooltip="'Roberts Space Industries'"
          href="https://robertsspaceindustries.com/"
          target="_blank"
          rel="noopener"
        >
          RSI
        </a>
        |
        <router-link :to="{ name: 'privacy-policy' }">
          {{ $t('nav.privacyPolicy') }}
        </router-link>
        |
        <router-link :to="{ name: 'cookie-policy' }">
          {{ $t('nav.cookiePolicy') }}
        </router-link>
        |
        <router-link :to="{ name: 'impressum' }">
          {{ $t('nav.impressum') }}
        </router-link>
        <span class="hidden-xs">
          |
        </span>
        <br class="visible-xs">
        <a
          v-tooltip="'Twitter'"
          href="https://twitter.com/FleetYardsNet"
          target="_blank"
          rel="noopener"
          aria-label="Twitter"
        >
          <i class="fab fa-twitter" />
        </a>
        |
        <a
          v-tooltip="'Github'"
          href="https://github.com/fleetyards"
          target="_blank"
          rel="noopener"
          aria-label="Github"
        >
          <i class="fab fa-github" />
        </a>
        |
        <a
          v-tooltip="'Discord'"
          href="https://discord.gg/6EQKAsb"
          target="_blank"
          rel="noopener"
          aria-label="Discrod"
        >
          <i class="fab fa-discord" />
        </a>
        |
        <a
          href="https://api.fleetyards.net"
          target="_blank"
          rel="noopener"
        >
          {{ $t('nav.api') }}
        </a>
      </div>
      <div class="app-footer-support">
        {{ $t('labels.supportUs') }}
        <a
          href="https://paypal.me/pools/c/83jQLadz60"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-paypal" />
          PayPal
        </a>
        {{ $t('labels.or') }}
        <a
          href="https://www.patreon.com/fleetyards"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-patreon" />
          Patreon
        </a>
      </div>
      <div class="app-footer-item">
        <p>
          <span>Copyright &copy; {{ new Date().getFullYear() }}</span>
          Torlek Maru
        </p>
        <p class="rsi-disclaimer">
          This is an unofficial Star Citizen fansite, not affiliated with the Cloud Imperium group
          of companies.<br>
          All content on this site not authored by its host or users are property of their
          respective owners.<br>
          Star Citizen®, Squadron 42®, Roberts Space Industries®, and Cloud Imperium® are<br>
          registered trademarks of Cloud Imperium Rights LLC. All rights reserved.
        </p>
      </div>
      <div class="app-community-logo" />
      <div class="app-version">
        {{ codename }} ({{ version }})
        <span
          v-tooltip="gitRevision"
          :class="{
            online: online,
          }"
          class="git-revision"
          @click="copyGitRevision"
        >
          <i class="far fa-fingerprint" />
        </span>
      </div>
    </div>
  </footer>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  computed: {
    ...mapGetters([
      'online',
    ]),

    ...mapGetters('app', [
      'version',
      'codename',
      'gitRevision',
    ]),
  },

  methods: {
    copyGitRevision() {
      this.$copyText(this.gitRevision).then(() => {
        this.$success({
          text: this.$t('messages.copyGitRevision.success'),
        })
      }, () => {
        this.$alert({
          text: this.$t('messages.copyGitRevision.failure'),
        })
      })
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
