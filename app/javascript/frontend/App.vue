<template>
  <div
    id="app"
    :class="{
      'navbar-visible': !navbarCollapsed,
    }"
    class="app-body"
  >
    <div
      :key="$store.state.backgroundImage"
      v-lazy:background-image="$store.state.backgroundImage"
      class="background-image"
    />
    <transition
      name="fade"
      mode="out-in"
      appear
    >
      <Navigation
        v-show="!$route.meta.hideNavigation"
        ref="navigation"
      />
    </transition>
    <transition
      name="fade"
      mode="out-in"
      appear
    >
      <router-view class="main" />
    </transition>
    <BackToTop visible-offset="500" />
    <AppFooter class="app-footer" />
  </div>
</template>

<script>
import BackToTop from 'frontend/components/BackToTop'
import Updates from 'frontend/mixins/Updates'
import CurrentUser from 'frontend/mixins/CurrentUser'
import CheckAppVersion from 'frontend/mixins/CheckAppVersion'
import RenewSession from 'frontend/mixins/RenewSession'
import Navigation from 'frontend/partials/Navigation'
import AppFooter from 'frontend/partials/AppFooter'
import { mapGetters } from 'vuex'
import { requestPermission } from 'frontend/lib/Noty'

export default {
  name: 'App',
  components: {
    Navigation,
    AppFooter,
    BackToTop,
  },
  mixins: [Updates, CurrentUser, CheckAppVersion, RenewSession],
  computed: {
    ...mapGetters([
      'isAuthenticated',
      'navbarCollapsed',
      'overlayVisible',
    ]),
  },
  watch: {
    $route() {
      this.setBackground()
      if (this.isAuthenticated) {
        this.fetchHangar()
      }
    },
    navbarCollapsed: 'setNoScroll',
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
    this.redirectToLastRoute()
    this.checkMobile()

    if (this.isAuthenticated) {
      requestPermission()
      this.fetchHangar()
    }

    window.addEventListener('online', this.online)
    window.addEventListener('offline', this.offline)
    window.addEventListener('resize', this.checkMobile)
    window.addEventListener('resize', this.checkMobile)
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.checkMobile)
    window.removeEventListener('online', this.online)
    window.removeEventListener('offline', this.offline)
  },
  methods: {
    offline() {
      this.$store.commit('setOnlineStatus', false)
    },
    online() {
      this.$store.commit('setOnlineStatus', true)
    },
    checkMobile() {
      this.$store.commit('setMobile', document.documentElement.clientWidth < 992)
    },
    setNoScroll() {
      if (!this.navbarCollapsed || this.overlayVisible) {
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
    redirectToLastRoute() {
      if (!this.$store.state.lastRoute || !navigator.standalone) {
        return
      }
      if (this.$store.state.lastRoute.name !== this.$route.name) {
        this.$router.replace(this.$store.state.lastRoute)
      }
    },
    async fetchHangar() {
      if (!['models', 'model', 'fleet', 'hangar'].includes(this.$route.name)) {
        return
      }
      const response = await this.$api.get('vehicles/hangar-items')
      if (!response.error) {
        this.$store.commit('setHangar', response.data)
      }
    },
  },
}
</script>
