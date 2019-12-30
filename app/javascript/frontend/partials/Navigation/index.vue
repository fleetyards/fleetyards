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
        Toggle Navigation
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
      :class="{
        'nav-container-slim': slim,
      }"
      class="nav-container"
    >
      <div class="nav-container-inner">
        <ul v-if="!isAuthenticated">
          <NavItem
            v-for="(navItem, index) in guestNavItems"
            :key="`guest-${index}`"
            :item="navItem"
            :slim="slim"
          />
        </ul>
        <ul v-if="isAuthenticated && currentUser">
          <NavItem
            :item="userNavItem"
            :slim="slim"
            class="user-menu"
          >
            <Avatar
              :avatar="currentUser.avatar"
              size="small"
            />
            <span
              v-if="!slim"
              class="username"
            >
              {{ currentUser.username }}
            </span>
          </NavItem>
        </ul>
        <ul>
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
            }"
            :slim="slim"
          >
            <i
              v-tooltip="slim && toggleSlimLabel"
              :class="{
                'fa-chevron-double-right': slim,
                'fa-chevron-double-left': !slim,
              }"
              class="fal"
            />
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
import { mapGetters } from 'vuex'
import Avatar from 'frontend/components/Avatar'

export default {
  name: 'Navigation',

  components: {
    QuickSearch,
    NavItem,
    FleetsNavItem,
    Avatar,
  },

  data() {
    return {
      shipsRouteActive: false,
      userRouteActive: false,
      cargoRouteActive: false,
      stationsRouteActive: false,
      stationRouteActive: false,
      shopRouteActive: false,
      starsystemRouteActive: false,
      searchQuery: null,
      roadmapsRouteActive: false,
      roadmapRouteActive: false,
      roadmapChangesRouteActive: false,
      roadmapShipsRouteActive: false,
      fleetsRouteActive: false,
      guestNavItems: [{
        to: { name: 'login' },
        label: this.$t('nav.login'),
        icon: 'fad fa-sign-in',
      }, {
        divider: true,
      }],
      fleets: [{
        slug: 'merc',
        name: 'MERC',
        logo: 'https://robertsspaceindustries.com/media/p7e22y3wa5wv2r/heap_infobox/MERCCORP-Logo.png?v=1449687402',
      }],
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

    ...mapGetters('hangar', {
      hangarPreview: 'preview',
    }),

    userNavItem() {
      return {
        active: this.userRouteActive,
        key: 'user',
        submenu: [{
          to: { name: 'settings' },
          icon: 'fad fa-cog',
          label: this.$t('nav.settings.index'),
          active: this.userRouteActive,
        }, {
          divider: true,
        }, {
          action: this.logout,
          icon: 'fad fa-sign-out',
          label: this.$t('nav.logout'),
        }],
      }
    },

    toggleSlimLabel() {
      if (this.slim) {
        return this.$t('nav.toggleSlimExpand')
      }

      return this.$t('nav.toggleSlimCollapse')
    },

    navRoutes() {
      return this.filterRoutes(this.$router.options.routes).map(this.mapRoutes)
    },

    navItems() {
      console.log(
        this.navRoutes,
      )
      return [
        {
          to: { name: 'home' },
          exact: true,
          icon: 'fad fa-home-alt',
          label: this.$t('nav.home'),
        },
        ...[this.hangarNavItem],
        {
          to: { name: 'models' },
          icon: 'fad fa-starship',
          label: this.$t('nav.models'),
          active: this.shipsRouteActive,
        },
        ...[this.stationsNavItem],
        ...[this.fleetsNavItem],
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
        ...[this.roadmapNavItem],
        {
          to: { name: 'stats' },
          icon: 'fad fa-chart-bar',
          label: this.$t('nav.stats'),
        },
      ]
    },

    hangarNavItem() {
      if (this.isAuthenticated || !this.hangarPreview) {
        return {
          to: { name: 'hangar' },
          icon: 'fad fa-bookmark',
          label: this.$t('nav.hangar'),
        }
      }

      return {
        to: { name: 'hangar-preview' },
        icon: 'fal fa-bookmark',
        label: this.$t('nav.hangar'),
      }
    },

    stationsNavItem() {
      return {
        icon: 'fad fa-planet-ringed',
        label: this.$t('nav.stations.index'),
        active: this.stationsRouteActive,
        key: 'stations',
        submenu: [{
          to: { name: 'stations' },
          icon: 'fad fa-planet-ringed',
          label: this.$t('nav.stations.overview'),
        }, {
          to: { name: 'starsystems' },
          icon: 'fad fa-solar-system',
          label: this.$t('nav.stations.starsystems'),
          active: this.starsystemRouteActive,
        }, {
          divider: true,
        }, {
          to: { name: 'shops' },
          icon: 'fad fa-store-alt',
          label: this.$t('nav.stations.shops'),
          active: this.shopRouteActive,
        }],
      }
    },

    roadmapNavItem() {
      return {
        icon: 'fad fa-tasks-alt',
        label: this.$t('nav.roadmap.index'),
        active: this.roadmapsRouteActive,
        key: 'roadmap',
        submenu: [{
          to: { name: 'roadmap' },
          icon: 'fad fa-tasks-alt',
          label: this.$t('nav.roadmap.overview'),
          active: this.roadmapRouteActive,
        }, {
          to: { name: 'roadmap-changes' },
          icon: 'fad fa-tasks',
          label: this.$t('nav.roadmap.changes'),
          active: this.roadmapChangesRouteActive,
        }, {
          to: { name: 'roadmap-ships' },
          icon: 'fad fa-rocket-launch',
          label: this.$t('nav.roadmap.ships'),
          active: this.roadmapShipsRouteActive,
        }],
      }
    },

    fleetsNavItem() {
      return {
        component: 'FleetsNavItem',
        label: this.$t('nav.fleets.index'),
        active: this.fleetsRouteActive,
        key: 'fleets',
        submenu: [
          {
            to: { name: 'fleets' },
            icon: 'fal fa-matrix',
            label: this.$t('nav.fleets.index'),
          },
          ...this.fleets.map((item) => ({
            to: { name: 'fleet', params: { slug: item.slug } },
            label: item.name,
            image: item.logo,
          })),
          {
            to: { name: 'fleet-add' },
            icon: 'fal fa-plus',
            label: this.$t('nav.fleets.add'),
          },
        ],
      }
    },

    slim() {
      return this.navSlim && !this.mobile
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
      this.checkRoutes()
      this.close()
    },
  },

  mounted() {
    this.checkRoutes()
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
    filterRoutes(routes) {
      return routes.filter((item) => !!item.meta?.nav)
        .filter((item) => !item.meta?.needsAuthentication
          || item.meta?.needsAuthentication === this.isAuthenticated)
        .filter((item) => !item.meta?.guest || item.meta?.guest !== this.isAuthenticated)
    },

    mapRoutes(route) {
      const submenuRoutes = this.filterRoutes(route.children || []).map(this.mapRoutes)
      const { nav } = route.meta || {}

      return {
        to: {
          name: route.name,
        },
        component: nav.component || null,
        icon: nav.icon || null,
        label: (nav.label ? this.$t(`nav.${nav.label}`) : this.$t(`nav.${route.name}`)),
        submenu: submenuRoutes.length ? submenuRoutes : null,
      }
    },

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

    checkRoutes() {
      const { path } = this.$route
      this.shipsRouteActive = (path.includes('ships') || path.includes('manufacturers')
        || path.includes('components') || path.includes('compare/ships')) && !path.includes('roadmap/ships')
      this.userRouteActive = path.includes('settings')
      this.starsystemRouteActive = path.includes('starsystems') || path.includes('celestial-objects')
      this.stationsRouteActive = path.includes('stations') || path.includes('shops') || this.starsystemRouteActive
      this.stationRouteActive = path.includes('stations') && !path.includes('shops')
      this.shopRouteActive = path.includes('shops')
      this.cargoRouteActive = path.includes('cargo') || path.includes('commodities')
      this.roadmapsRouteActive = path.includes('roadmap')
      this.roadmapRouteActive = path.includes('roadmap') && !path.includes('roadmap/changes') && !path.includes('roadmap/ships')
      this.fleetsRouteActive = path.includes('fleets')
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
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
