<template>
  <div
    id="app"
    :class="{
      'nav-visible': !navCollapsed,
      [`page-${$route.name}`]: true,
    }"
    class="app-body"
  >
    <BackgroundImage />

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

    <AppModal />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import Updates from 'frontend/mixins/Updates'
import userCollection from 'frontend/api/collections/User'
import versionCollection from 'frontend/api/collections/Version'
import Navigation from 'frontend/core/components/Navigation'
import AppFooter from 'frontend/core/components/AppFooter'
import AppModal from 'frontend/core/components/AppModal'
import BackgroundImage from 'frontend/core/components/BackgroundImage'
import { requestPermission } from 'frontend/lib/Noty'

const CHECK_VERSION_INTERVAL = 1800 * 1000 // 30 mins

@Component<FrontendApp>({
  components: {
    BackgroundImage,
    Navigation,
    AppFooter,
    AppModal,
  },
  mixins: [Updates],
})
export default class FrontendApp extends Vue {
  sessionRenewInterval: boolean = null

  @Getter('navCollapsed', { namespace: 'app' }) navCollapsed: boolean

  @Getter('overlayVisible', { namespace: 'app' }) overlayVisible: boolean

  @Getter('isAuthenticated', { namespace: 'session' }) isAuthenticated: boolean

  @Getter('currentUser', { namespace: 'session' }) currentUser: User

  @Getter('cookies', { namespace: 'cookies' }) cookies

  @Getter('infoVisible', { namespace: 'cookies' })
  cookiesInfoVisible: boolean

  get ahoyAccepted() {
    return this.cookies.ahoy
  }

  @Watch('navCollapsed')
  onNavCollapsedChange() {
    this.setNoScroll()
  }

  @Watch('overlayVisible')
  onOverlayVisibleChange() {
    this.setNoScroll()
  }

  @Watch('isAuthenticated')
  onAuthenticationChange() {
    if (this.isAuthenticated) {
      requestPermission()
      this.fetchCurrentUser()
    } else {
      if (this.sessionRenewInterval) {
        clearInterval(this.sessionRenewInterval)
      }

      if (this.$route.meta.needsAuthentication) {
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        this.$router.push({ name: 'login' }).catch(() => {})
      }
    }
  }

  @Watch('$route')
  onRouteChange() {
    if (this.cookiesInfoVisible && this.$route.name !== 'privacy-policy') {
      this.openPrivacySettings()
    } else if (
      this.cookiesInfoVisible &&
      this.$route.name === 'privacy-policy'
    ) {
      this.$comlink.$emit('close-modal', true)
    }
  }

  @Watch('ahoyAccepted')
  onAhoyAcceptedChange() {
    if (this.ahoyAccepted) {
      this.$ahoy.trackAll()
    } else {
      window.location.reload(true)
    }
  }

  created() {
    this.setNoScroll()
    this.checkMobile()

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

    this.$comlink.$on('open-privacy-settings', this.openPrivacySettings)

    window.addEventListener('resize', this.checkMobile)
    this.$comlink.$on('user-update', this.fetchCurrentUser)
    this.$comlink.$on('fleet-create', this.fetchCurrentUser)
    this.$comlink.$on('fleet-update', this.fetchCurrentUser)
  }

  beforeDestroy() {
    window.removeEventListener('resize', this.checkMobile)
    this.$comlink.$off('user-update')
    this.$comlink.$off('fleet-create')
    this.$comlink.$off('fleet-update')
  }

  openPrivacySettings(settings = false) {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/core/components/PrivacySettings'),
      fixed: true,
      props: {
        settings,
      },
    })
  }

  checkMobile() {
    this.$store.commit('setMobile', document.documentElement.clientWidth < 992)
  }

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
  }

  async fetchCurrentUser() {
    await this.$store.commit(
      'session/setCurrentUser',
      await userCollection.current(),
    )
  }

  async checkVersion() {
    await this.$store.dispatch(
      'app/updateVersion',
      await versionCollection.current(),
    )
  }
}
</script>
