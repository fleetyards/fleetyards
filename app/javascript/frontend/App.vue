<template>
  <div
    id="app"
    :class="{
      'nav-visible': !navCollapsed,
      [`page-${$route.name}`]: true,
    }"
    class="app-body"
  >
    <div :class="{ webp: webpSupported }" class="background-image" />
    <div class="app-content">
      <transition name="fade" mode="out-in" appear>
        <Navigation />
      </transition>
      <div class="main-wrapper">
        <div class="main-inner">
          <transition name="fade" mode="out-in" appear>
            <router-view :key="$route.path" class="main" />
          </transition>
        </div>
        <AppFooter />
      </div>
    </div>
    <PrivacySettings ref="privacySettings" :open="cookiesInfoVisible" />
  </div>
</template>

<script>
import axios from 'axios'
import Updates from 'frontend/mixins/Updates'
import userCollection from 'frontend/api/collections/User'
import versionCollection from 'frontend/api/collections/Version'
import Navigation from 'frontend/core/components/Navigation'
import AppFooter from 'frontend/core/components/AppFooter'
import PrivacySettings from 'frontend/core/components/PrivacySettings'
import { mapGetters } from 'vuex'
import { requestPermission } from 'frontend/lib/Noty'

const CHECK_VERSION_INTERVAL = 1800 * 1000 // 30 mins

export default {
  name: 'FrontendApp',

  components: {
    Navigation,
    AppFooter,
    PrivacySettings,
  },

  mixins: [Updates],

  data() {
    return {
      webpSupported: true,
      sessionRenewInterval: null,
    }
  },

  computed: {
    ...mapGetters('app', ['navCollapsed', 'overlayVisible']),

    ...mapGetters('session', [
      'isAuthenticated',
      'currentUser',
      // 'authTokenRenewAt',
    ]),

    ...mapGetters('cookies', {
      cookies: 'cookies',
      cookiesInfoVisible: 'infoVisible',
    }),

    ahoyAccepted() {
      return this.cookies.ahoy
    },
  },

  watch: {
    navCollapsed: 'setNoScroll',

    overlayVisible: 'setNoScroll',

    isAuthenticated() {
      if (this.isAuthenticated) {
        requestPermission()
        this.fetchCurrentUser()
      } else {
        if (this.sessionRenewInterval) {
          clearInterval(this.sessionRenewInterval)
        }

        if (this.$route.meta.needsAuthentication) {
          this.$router.push({ name: 'login' })
        }
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
    this.checkMobile()
    this.checkWebpSupport()

    if (this.isAuthenticated) {
      requestPermission()
      this.fetchCurrentUser()
    }

    if (this.ahoyAccepted) {
      this.$ahoy.trackAll()
    }

    this.checkVersion()

    setInterval(() => {
      this.checkVersion()
    }, CHECK_VERSION_INTERVAL)

    this.$comlink.$on('openPrivacySettings', this.openPrivacySettings)

    window.addEventListener('resize', this.checkMobile)
    this.$comlink.$on('userUpdate', this.fetchCurrentUser)
    this.$comlink.$on('fleetCreate', this.fetchCurrentUser)
    this.$comlink.$on('fleetUpdate', this.fetchCurrentUser)
  },

  beforeDestroy() {
    window.removeEventListener('resize', this.checkMobile)
    this.$comlink.$off('userUpdate')
    this.$comlink.$off('fleetCreate')
    this.$comlink.$off('fleetUpdate')
  },

  methods: {
    async checkWebpSupport() {
      if (typeof createImageBitmap === 'undefined') {
        return false
      }

      const webpData =
        'data:image/webp;base64,UklGRh4AAABXRUJQVlA4TBEAAAAvAAAAAAfQ//73v/+BiOh/AAA='
      const response = await axios.get(webpData, { responseType: 'blob' })

      this.webpSupported = await createImageBitmap(response.data).then(
        () => true,
        () => false,
      )

      return this.webpSupported
    },

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
      if (!this.navCollapsed) {
        document.body.classList.add('nav-visible')
      } else {
        document.body.classList.remove('nav-visible')
      }

      if (!this.navCollapsed || this.overlayVisible) {
        document.body.classList.add('no-scroll')
      } else {
        document.body.classList.remove('no-scroll')
      }
    },

    async fetchCurrentUser() {
      await this.$store.commit(
        'session/setCurrentUser',
        await userCollection.current(),
      )
    },

    async checkVersion() {
      await this.$store.dispatch(
        'app/updateVersion',
        await versionCollection.current(),
      )
    },
  },
}
</script>
