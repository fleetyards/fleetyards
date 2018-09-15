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
        <router-link :to="{ name: 'privacy-policy' }">{{ t('nav.privacyPolicy') }}</router-link>
        |
        <router-link :to="{ name: 'impressum' }">{{ t('nav.impressum') }}</router-link>
        <span class="hidden-xs">|</span>
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
          href="https://api.fleetyards.net"
          target="_blank"
          rel="noopener"
        >
          {{ t('nav.api') }}
        </a>
      </div>
      <div class="app-footer-item">
        Copyright &copy; {{ new Date().getFullYear() }}
        <a
          href="mailto:info@mortik.de"
          target="_blank"
          rel="noopener"
        >
          Marten Klitzke - mortik.
        </a>
      </div>
      <div class="app-version">
        {{ appCodename }} ({{ appVersion }})
      </div>
    </div>
  </footer>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import { mapGetters } from 'vuex'

export default {
  mixins: [I18n],
  computed: {
    ...mapGetters([
      'appVersion',
      'appCodename',
    ]),
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
