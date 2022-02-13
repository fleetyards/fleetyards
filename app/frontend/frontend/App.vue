<template>
  <div id="app" :class="classes" class="app-body">
    <BackgroundImage />

    <transition name="fade" mode="out-in">
      <NavigationMobile v-if="mobile" />
    </transition>
    <transition name="fade" mode="out-in">
      <Navigation />
    </transition>
    <div class="main-wrapper" :class="{ 'slim-nav': navSlim }">
      <div class="main-inner">
        <NavigationHeader />

        <transition name="fade" mode="out-in">
          <router-view :key="$route.path" class="main" />
        </transition>
      </div>

      <AppFooter />
    </div>

    <AppShoppingCart />

    <AppModal />
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import Updates from '@/frontend/mixins/Updates'
import userCollection from '@/frontend/api/collections/User'
import versionCollection from '@/frontend/api/collections/Version'
import Navigation from '@/frontend/core/components/Navigation/index.vue'
import NavigationHeader from '@/frontend/core/components/Navigation/Header/index.vue'
import NavigationMobile from '@/frontend/core/components/Navigation/Mobile/index.vue'
import AppFooter from '@/frontend/core/components/AppFooter/index.vue'
import AppModal from '@/frontend/core/components/AppModal/index.vue'
import AppShoppingCart from '@/frontend/core/components/AppShoppingCart/index.vue'
import BackgroundImage from '@/frontend/core/components/BackgroundImage/index.vue'
import { requestPermission } from '@/frontend/lib/Noty'

const CHECK_VERSION_INTERVAL = 1800 * 1000 // 30 mins

export default {
  name: 'FrontendApp',

  components: {
    BackgroundImage,
    Navigation,
    NavigationHeader,
    NavigationMobile,
    AppFooter,
    AppModal,
    AppShoppingCart,
  },

  mixins: [Updates],

  data() {
    return {
      sessionRenewInterval: null,
    }
  },

  computed: {
    ...mapGetters(['mobile']),

    ...mapGetters('app', ['navCollapsed', 'navSlim', 'overlayVisible']),

    ...mapGetters('session', ['isAuthenticated', 'currentUser']),

    ...mapGetters('cookies', {
      cookies: 'cookies',
      infoVisible: 'cookiesInfoVisible',
    }),

    ahoyAccepted() {
      return this.cookies.ahoy
    },

    classes() {
      return [`page-${this.$route.name}`]
    },
  },

  watch: {
    navCollapsed() {
      this.setNoScroll()
    },

    overlayVisible() {
      this.setNoScroll()
    },

    isAuthenticated() {
      if (this.isAuthenticated) {
        requestPermission()
        this.fetchCurrentUser()
      } else {
        if (this.sessionRenewInterval) {
          clearInterval(this.sessionRenewInterval)
        }

        if (this.$route.meta.needsAuthentication) {
          this.$router.push({ name: 'login' }).catch(() => {})
        }
      }
    },

    $route() {
      if (this.cookiesInfoVisible && this.$route.name !== 'privacy-policy') {
        this.openPrivacySettings()
      } else if (
        this.cookiesInfoVisible &&
        this.$route.name === 'privacy-policy'
      ) {
        this.$comlink.$emit('close-modal', true)
      }
    },

    ahoyAccepted() {
      if (this.ahoyAccepted) {
        this.$ahoy.trackView()
        // this.$ahoy.trackClicks()
        this.$ahoy.trackSubmits('form')
        this.$ahoy.trackChanges('input, textarea, select')
      } else {
        window.location.reload(true)
      }
    },
  },

  created() {
    this.setNoScroll()
    this.checkMobile()

    if (this.isAuthenticated) {
      requestPermission()
      this.fetchCurrentUser()
    }

    if (this.ahoyAccepted) {
      this.$ahoy.trackView()
      // this.$ahoy.trackClicks()
      this.$ahoy.trackSubmits('form')
      this.$ahoy.trackChanges('input, textarea, select')
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
  },

  beforeDestroy() {
    window.removeEventListener('resize', this.checkMobile)
    this.$comlink.$off('user-update')
    this.$comlink.$off('fleet-create')
    this.$comlink.$off('fleet-update')
  },

  methods: {
    openPrivacySettings(settings = false) {
      this.$comlink.$emit('open-modal', {
        component: () => import('@/frontend/core/components/PrivacySettings'),
        fixed: true,
        props: {
          settings,
        },
      })
    },

    checkMobile() {
      this.$store.commit(
        'setMobile',
        document.documentElement.clientWidth < 992
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
        await userCollection.current()
      )
    },

    async checkVersion() {
      await this.$store.dispatch(
        'app/updateVersion',
        await versionCollection.current()
      )
    },
  },
}
</script>
