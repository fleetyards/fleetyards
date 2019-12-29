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
    <NetworkStatus />
    <div class="app-content">
      <transition
        name="fade"
        mode="out-in"
        appear
      >
        <Navigation />
      </transition>
      <div class="main-wrapper">
        <div class="main-inner">
          <transition
            name="fade"
            mode="out-in"
            appear
          >
            <router-view class="main" />
          </transition>
        </div>
        <AppFooter />
      </div>
    </div>
    <BackToTop visible-offset="500" />
    <CookiesBanner />
  </div>
</template>

<script>
import BackToTop from 'frontend/partials/BackToTop'
import Updates from 'frontend/mixins/Updates'
import CurrentUser from 'frontend/mixins/CurrentUser'
import RenewSession from 'frontend/mixins/RenewSession'
import Navigation from 'frontend/partials/Navigation'
import AppFooter from 'frontend/partials/AppFooter'
import CookiesBanner from 'frontend/partials/CookiesBanner'
import NetworkStatus from 'frontend/components/NetworkStatus'
import { mapGetters } from 'vuex'
import { requestPermission } from 'frontend/lib/Noty'

export default {
  name: 'FrontendApp',

  components: {
    Navigation,
    AppFooter,
    BackToTop,
    CookiesBanner,
    NetworkStatus,
  },

  mixins: [
    Updates,
    CurrentUser,
    RenewSession,
  ],

  computed: {
    ...mapGetters([
      'backgroundImage',
    ]),

    ...mapGetters('app', [
      'navCollapsed',
      'overlayVisible',
    ]),

    ...mapGetters('session', [
      'isAuthenticated',
    ]),
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
  },

  created() {
    this.setNoScroll()
    this.setBackground()
    this.checkMobile()

    if (this.isAuthenticated) {
      requestPermission()
      this.fetchHangar()
    }

    window.addEventListener('resize', this.checkMobile)
  },

  beforeDestroy() {
    window.removeEventListener('resize', this.checkMobile)
  },

  methods: {
    checkMobile() {
      this.$store.commit('setMobile', document.documentElement.clientWidth < 992)
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
        backgroundImage = require('images/bg-0.jpg')
      }
      this.$store.commit('setBackgroundImage', backgroundImage)
    },

    async fetchHangar() {
      if (!['models', 'model', 'fleet', 'hangar'].includes(this.$route.name)) {
        return
      }
      this.$store.dispatch('hangar/fetch')
    },
  },
}
</script>
