<template>
  <div
    id="app"
    :class="{
      'nav-visible': !navCollapsed,
    }"
    class="app-body"
  >
    <div
      v-if="backgroundImage"
      :key="backgroundImage"
      v-lazy:background-image="backgroundImage"
      class="background-image"
    />
    <div class="app-content">
      <transition name="fade" mode="out-in" appear>
        <Navigation />
      </transition>
      <div class="main-wrapper">
        <div class="main-inner">
          <transition name="fade" mode="out-in" appear>
            <router-view class="main" />
          </transition>
        </div>
        <AppFooter />
      </div>
    </div>
    <BackToTop visible-offset="500" />
    <PrivacySettings ref="privacySettings" :open="cookiesInfoVisible" />
  </div>
</template>

<script>
import BackToTop from 'frontend/partials/BackToTop'
import Updates from 'frontend/mixins/Updates'
import CurrentUser from 'frontend/mixins/CurrentUser'
import RenewSession from 'frontend/mixins/RenewSession'
import CheckVersion from 'frontend/mixins/CheckVersion'
import Navigation from 'frontend/partials/Navigation'
import AppFooter from 'frontend/partials/AppFooter'
import PrivacySettings from 'frontend/partials/PrivacySettings'
import { mapGetters } from 'vuex'
import { requestPermission } from 'frontend/lib/Noty'

export default {
  name: 'FrontendApp',

  components: {
    Navigation,
    AppFooter,
    BackToTop,
    PrivacySettings,
  },

  mixins: [Updates, CurrentUser, RenewSession, CheckVersion],

  computed: {
    ...mapGetters(['backgroundImage']),

    ...mapGetters('app', ['navCollapsed', 'overlayVisible']),

    ...mapGetters('session', ['isAuthenticated']),

    ...mapGetters('cookies', {
      cookies: 'cookies',
      cookiesInfoVisible: 'infoVisible',
    }),

    ahoyAccepted() {
      return this.cookies.ahoy
    },
  },

  watch: {
    $route() {
      this.setBackground()

      if (this.isAuthenticated) {
        this.fetchHangar()
      }
    },

    navCollapsed: 'setNoScroll',

    overlayVisible: 'setNoScroll',

    isAuthenticated() {
      if (this.isAuthenticated) {
        requestPermission()
        this.fetchHangar()
      } else if (this.$route.meta.needsAuthentication) {
        this.$router.push({ name: 'login' })
      }
    },

    ahoyAccepted() {
      if (this.ahoyAccepted) {
        this.$ahoy.trackAll()
      } else {
        window.location.reload(true)
      }
    },
  },

  created() {
    this.setNoScroll()
    this.setBackground()
    this.checkMobile()

    if (this.isAuthenticated) {
      requestPermission()
      this.fetchHangar()
    }

    if (this.ahoyAccepted) {
      this.$ahoy.trackAll()
    }

    this.$comlink.$on('openPrivacySettings', this.openPrivacySettings)

    window.addEventListener('resize', this.checkMobile)
  },

  beforeDestroy() {
    window.removeEventListener('resize', this.checkMobile)
  },

  methods: {
    openPrivacySettings(settings = false) {
      this.$refs.privacySettings.open(settings)
    },

    checkMobile() {
      this.$store.commit(
        'setMobile',
        document.documentElement.clientWidth < 992,
      )
    },

    setNoScroll() {
      if (!this.navCollapsed || this.overlayVisible) {
        document.documentElement.classList.add('no-scroll')
        document.body.classList.add('no-scroll')
      } else {
        document.documentElement.classList.remove('no-scroll')
        document.body.classList.remove('no-scroll')
      }
    },

    setBackground() {
      let { backgroundImage } = this.$route.meta
      if (!backgroundImage) {
        // eslint-disable-next-line global-require
        backgroundImage = require('images/bg-0.jpg').default
      }
      this.$store.commit('setBackgroundImage', backgroundImage)
    },

    async fetchHangar() {
      if (!['models', 'model', 'fleet', 'hangar'].includes(this.$route.name)) {
        return
      }

      const response = await this.$api.get('vehicles/hangar-items', null, true)
      if (!response.error) {
        this.$store.dispatch('hangar/saveHangar', response.data)
      }
    },
  },
}
</script>
