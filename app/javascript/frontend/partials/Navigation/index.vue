<template>
  <nav
    ref="navigation"
    :class="{
      'visible': !navCollapsed,
      'nav-slim': slim,
    }"
    role="navigation"
  >
    <button
      v-if="mobile"
      :class="{
        collapsed: navCollapsed,
      }"
      class="nav-toggle"
      type="button"
      aria-label="Toggle Navigation"
      @click.stop.prevent="toggle"
    >
      <span class="sr-only">
        {{ $t('labels.toggleNavigation') }}
      </span>
      <span class="icon-bar top-bar" />
      <span class="icon-bar middle-bar" />
      <span class="icon-bar bottom-bar" />
    </button>
    <div
      v-if="nodeEnv && !mobile"
      :class="{
        'spacing-right': this.$route.name === 'home',
      }"
      class="environment-label"
    >
      <span :class="environmentLabelClasses">
        <i class="far fa-info-circle" />
        {{ nodeEnv }}
      </span>
      <span
        class="git-revision"
        :class="environmentLabelClasses"
        @click="copyGitRevision"
      >
        <i class="far fa-fingerprint" />
        {{ gitRevision }}
      </span>
    </div>
    <QuickSearch v-if="$route.meta.quickSearch" />
    <div
      :key="navKey"
      :class="{
        'nav-container-slim': slim,
      }"
      class="nav-container"
    >
      <div class="nav-container-inner">
        <ul v-if="isFleetRoute">
          <component
            :is="navItem.component || 'NavItem'"
            v-for="(navItem, index) in fleetNavItems"
            :key="`fleet-nav-${index}`"
            :item="navItem"
            :slim="slim"
          />
        </ul>
        <ul v-else>
          <component
            :is="navItem.component || 'NavItem'"
            v-for="(navItem, index) in navItems"
            :key="`nav-${index}`"
            :item="navItem"
            :slim="slim"
          />
        </ul>
        <ul class="nav-bottom">
          <NavItem
            v-if="!mobile"
            :item="{
              action: toggleSlim,
              label: toggleSlimLabel,
            }"
            :slim="slim"
          >
            <span v-show="slim">
              <i class="fal fa-chevron-double-right" />
            </span>
            <span v-show="!slim">
              <i class="fal fa-chevron-double-left" />
            </span>
            <transition name="fade-nav">
              <span v-if="!slim">{{ toggleSlimLabel }}</span>
            </transition>
          </NavItem>
          <NavItem
            :item="{}"
            :slim="slim"
            class="logo-menu"
          >
            <img
              :src="require('images/favicon.png')"
              class="logo"
              alt="logo"
            >
            <transition name="fade-nav">
              <span v-if="!slim">{{ $t('app') }}</span>
            </transition>
          </NavItem>
        </ul>
      </div>
    </div>
  </nav>
</template>

<script>
import QuickSearch from 'frontend/partials/Navigation/QuickSearch'
import NavItem from 'frontend/partials/Navigation/NavItem'
import FleetsNavItem from 'frontend/partials/Navigation/FleetsNavItem'
import UserNavItem from 'frontend/partials/Navigation/UserNavItem'
import { mapGetters } from 'vuex'

export default {
  name: 'Navigation',

  components: {
    QuickSearch,
    NavItem,
    FleetsNavItem,
    UserNavItem,
  },

  data() {
    return {
      currentFleet: null,
      searchQuery: null,
    }
  },

  computed: {
    ...mapGetters([
      'mobile',
    ]),

    ...mapGetters('app', [
      'navCollapsed',
      'navSlim',
      'isUpdateAvailable',
      'gitRevision',
    ]),

    ...mapGetters('session', [
      'currentUser',
      'isAuthenticated',
    ]),

    ...mapGetters('fleet', {
      fleetPreview: 'preview',
    }),

    ...mapGetters('hangar', {
      hangarPreview: 'preview',
    }),

    fleets() {
      if (!this.currentUser) {
        return []
      }

      return this.currentUser.fleets
    },

    myFleets() {
      return this.fleets.filter((fleet) => !fleet.invitation)
    },

    toggleSlimLabel() {
      if (this.slim) {
        return this.$t('nav.toggleSlimExpand')
      }

      return this.$t('nav.toggleSlimCollapse')
    },

    navItems() {
      return [
        ...this.userNavItems,
        {
          to: { name: 'home' },
          exact: true,
          icon: 'fad fa-home-alt',
          label: this.$t('nav.home'),
        },
        ...this.hangarNavItems,
        {
          to: { name: 'models' },
          icon: 'fad fa-starship',
          label: this.$t('nav.models'),
        },
        ...this.stationsNavItems,
        ...this.fleetsNavItems,
        {
          to: { name: 'images' },
          icon: 'fad fa-images',
          label: this.$t('nav.images'),
        },
        {
          to: {
            name: 'trade-routes',
            query: {
              q: this.$store.state.filters['trade-routes'],
            },
          },
          icon: 'fad fa-pallet-alt',
          label: this.$t('nav.tradeRoutes'),
        },
        ...this.roadmapNavItems,
        {
          to: { name: 'stats' },
          icon: 'fad fa-chart-bar',
          label: this.$t('nav.stats'),
        },
      ]
    },

    userNavItems() {
      if (!this.isAuthenticated) {
        return [{
          to: { name: 'login' },
          label: this.$t('nav.login'),
          icon: 'fad fa-sign-in',
        }, {
          divider: true,
        }]
      }


      return [{
        component: 'UserNavItem',
        key: 'user',
        submenu: [{
          to: { name: 'settings' },
          icon: 'fad fa-cog',
          label: this.$t('nav.settings.index'),
        }, {
          divider: true,
        }, {
          action: this.logout,
          icon: 'fad fa-sign-out',
          label: this.$t('nav.logout'),
        }],
      }]
    },

    hangarNavItems() {
      if (this.isAuthenticated || !this.hangarPreview) {
        return [{
          to: { name: 'hangar' },
          icon: 'fad fa-bookmark',
          label: this.$t('nav.hangar'),
        }]
      }

      return [{
        to: { name: 'hangar-preview' },
        icon: 'fal fa-bookmark',
        label: this.$t('nav.hangar'),
      }]
    },

    stationsNavItems() {
      return [{
        icon: 'fad fa-planet-ringed',
        label: this.$t('nav.stations.index'),
        key: 'stations',
        submenu: [{
          to: { name: 'stations' },
          icon: 'fad fa-planet-ringed',
          label: this.$t('nav.stations.overview'),
        }, {
          to: { name: 'starsystems' },
          icon: 'fad fa-solar-system',
          label: this.$t('nav.stations.starsystems'),
        }, {
          divider: true,
        }, {
          to: { name: 'shops' },
          icon: 'fad fa-store-alt',
          label: this.$t('nav.stations.shops'),
        }],
      }]
    },

    roadmapNavItems() {
      return [{
        icon: 'fad fa-tasks-alt',
        label: this.$t('nav.roadmap.index'),
        key: 'roadmap',
        submenu: [{
          to: { name: 'roadmap' },
          icon: 'fad fa-tasks-alt',
          label: this.$t('nav.roadmap.overview'),
          exact: true,
        }, {
          to: { name: 'roadmap-changes' },
          icon: 'fad fa-tasks',
          label: this.$t('nav.roadmap.changes'),
        }, {
          to: { name: 'roadmap-ships' },
          icon: 'fad fa-rocket-launch',
          label: this.$t('nav.roadmap.ships'),
        }],
      }]
    },

    fleetNavItems() {
      if (!this.currentFleet) {
        return []
      }

      const officerItems = []
      if (this.currentFleet.role === 'admin' || this.currentFleet.role === 'officer') {
        officerItems.push({
          to: { name: 'fleet-members', params: { slug: this.currentFleet.slug } },
          label: this.$t('nav.fleets.members'),
          icon: 'fad fa-users',
        })
      }

      const adminItems = []
      if (this.currentFleet.role === 'admin') {
        adminItems.push({
          to: { name: 'fleet-settings', params: { slug: this.currentFleet.slug } },
          label: this.$t('nav.fleets.settings'),
          icon: 'fad fa-cogs',
        })
      }

      return [
        ...this.userNavItems,
        {
          to: { name: 'home' },
          exact: true,
          icon: 'fal fa-chevron-left',
          label: this.$t('nav.home'),
        },
        {
          to: { name: 'fleet', params: { slug: this.currentFleet.slug } },
          label: this.currentFleet.name,
          image: this.currentFleet.logo,
        },
        ...officerItems,
        ...adminItems,
      ]
    },


    fleetsNavItems() {
      const submenu = [
        ...this.myFleets.map((item) => ({
          to: { name: 'fleet', params: { slug: item.slug } },
          label: item.name,
          image: item.logo,
        })),
      ]


      if (this.isAuthenticated) {
        const invites = this.fleets.filter((item) => item.invitation)
        if (invites.length) {
          submenu.push({
            to: { name: 'fleet-invites' },
            icon: 'fad fa-envelope-open-text',
            label: this.$t('nav.fleets.invites'),
          })
        }
      }

      if (this.isAuthenticated || !this.fleetPreview) {
        submenu.push({
          to: { name: 'fleet-add' },
          icon: 'fal fa-plus',
          label: this.$t('nav.fleets.add'),
        })
      } else {
        submenu.push({
          to: { name: 'fleet-preview' },
          icon: 'fal fa-plus',
          label: this.$t('nav.fleets.add'),
        })
      }

      return [{
        component: 'FleetsNavItem',
        label: this.$t('nav.fleets.index'),
        key: 'fleets',
        submenu,
      }]
    },

    isFleetRoute() {
      const { path, name } = this.$route
      return path.includes('fleets') && name !== 'fleets' && name !== 'fleet-add' && name !== 'fleet-invites' && name !== 'fleet-preview'
    },

    slim() {
      return this.navSlim && !this.mobile
    },

    navKey() {
      const key = ['nav']

      if (this.isAuthenticated) {
        key.push('authenticated')
      }

      if (this.fleetPreview) {
        key.push('fleetPreview')
      }

      if (this.hangarPreview) {
        key.push('hangarPreview')
      }

      if (this.fleets.length) {
        key.push(this.fleets.map((item) => item.slug).join('-'))
      }

      return key.join('-')
    },

    environmentLabelClasses() {
      const cssClasses = ['pill']

      if (window.NODE_ENV === 'staging') {
        cssClasses.push('pill-warning')
      } else if (window.NODE_ENV === 'production') {
        cssClasses.push('pill-danger')
      }

      return cssClasses
    },

    nodeEnv() {
      if (window.NODE_ENV === 'production') {
        return null
      }

      return (window.NODE_ENV || '').toUpperCase()
    },
  },

  watch: {
    $route() {
      this.close()
    },

    isFleetRoute() {
      if (this.isFleetRoute) {
        this.fetchFleet()
      }
    },
  },

  mounted() {
    this.$comlink.$on('fleetUpdate', this.fetchFleet)
  },

  created() {
    document.addEventListener('click', this.documentClick)
  },

  destroyed() {
    document.removeEventListener('click', this.documentClick)
  },

  beforeDestroy() {
    this.close()
  },

  methods: {
    documentClick(event) {
      const element = this.$refs.navigation
      const { target } = event

      if (element !== target && !element.contains(target)) {
        this.close()
      }
    },

    toggle() {
      this.$store.commit('app/toggleNav')
    },

    toggleSlim() {
      this.$store.commit('app/toggleSlimNav')
    },

    open() {
      this.$store.commit('app/openNav')
    },

    close() {
      this.$store.commit('app/closeNav')
    },

    async logout() {
      await this.$store.dispatch('session/logout')
    },

    reload() {
      this.close()

      window.location.reload(true)
    },

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

    async fetchFleet() {
      const response = await this.$api.get(`fleets/${this.$route.params.slug}?nav`)

      if (!response.error) {
        this.currentFleet = response.data
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
