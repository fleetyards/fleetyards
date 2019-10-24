<template>
  <nav
    ref="navigation"
    :class="{
      'visible': !navCollapsed,
    }"
    role="navigation"
  >
    <button
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
      v-if="nodeEnv"
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
    <div class="nav-container">
      <img
        :src="require('images/logo.png')"
        class="logo"
        alt="logo"
      >
      <div class="nav-container-inner">
        <ul v-if="!isAuthenticated">
          <router-link
            :to="{ name: 'signup' }"
            tag="li"
          >
            <a>{{ $t('nav.signUp') }}</a>
          </router-link>
          <router-link
            :to="{ name: 'login' }"
            tag="li"
          >
            <a>{{ $t('nav.login') }}</a>
          </router-link>
          <li class="divider" />
        </ul>
        <ul v-if="isAuthenticated && currentUser">
          <li
            :class="{
              active: userRouteActive,
              open: userMenuOpen,
            }"
            class="sub-menu user-menu"
          >
            <a @click="toggleUserMenu">
              <div class="avatar">
                <div
                  v-if="currentUser.rsiVerified"
                  v-tooltip="$t('labels.rsiVerified')"
                  class="verified"
                >
                  <i class="fa fa-check" />
                </div>
                <img
                  v-if="citizen && citizen.avatar"
                  :src="citizen.avatar"
                  alt="avatar"
                  width="36"
                  height="36"
                >
                <div
                  v-else
                  class="no-avatar"
                >
                  <i class="fa fa-user" />
                </div>
              </div>
              <span class="username">
                {{ currentUser.username }}
              </span>
              <i class="fa fa-chevron-right" />
            </a>
            <b-collapse
              id="user-sub-menu"
              :visible="userMenuOpen"
              tag="ul"
            >
              <router-link
                :to="{ name: 'settings' }"
                tag="li"
              >
                <a>{{ $t('nav.settings.index') }}</a>
              </router-link>
              <li v-if="currentUser.rsiHandle">
                <a
                  :href="`https://robertsspaceindustries.com/citizens/${currentUser.rsiHandle}`"
                  target="_blank"
                  rel="noopener"
                >
                  {{ $t('nav.rsiProfile') }}
                </a>
              </li>
              <li class="divider" />
              <li>
                <a @click="logout">
                  {{ $t('nav.logout') }}
                </a>
              </li>
            </b-collapse>
          </li>
        </ul>
        <ul>
          <router-link
            :to="{ name: 'home' }"
            tag="li"
            exact
          >
            <a>{{ $t('nav.home') }}</a>
          </router-link>
          <router-link
            :to="{ name: 'models' }"
            tag="li"
          >
            <a>{{ $t('nav.models') }}</a>
          </router-link>
          <li
            :class="{
              active: stationsRouteActive,
              open: stationMenuOpen,
            }"
            class="sub-menu"
          >
            <a @click="toggleStationMenu">
              {{ $t('nav.stations.index') }}
              <i class="fa fa-chevron-right" />
            </a>
            <b-collapse
              id="stations-sub-menu"
              :visible="stationMenuOpen"
              tag="ul"
            >
              <router-link
                :to="{ name: 'stations' }"
                :class="{
                  active: stationRouteActive,
                }"
                active-class="router-active"
                tag="li"
              >
                <a>{{ $t('nav.stations.overview') }}</a>
              </router-link>
              <router-link
                :to="{ name: 'starsystems' }"
                :class="{
                  active: starsystemRouteActive,
                }"
                active-class="router-active"
                tag="li"
              >
                <a>{{ $t('nav.stations.starsystems') }}</a>
              </router-link>
              <li class="divider" />
              <router-link
                :to="{ name: 'shops' }"
                :class="{
                  active: shopRouteActive,
                }"
                active-class="router-active"
                tag="li"
              >
                <a>{{ $t('nav.stations.shops') }}</a>
              </router-link>
            </b-collapse>
          </li>
          <router-link
            :to="{ name: 'hangar' }"
            tag="li"
          >
            <a>{{ $t('nav.hangar') }}</a>
          </router-link>
          <router-link
            :to="{ name: 'images' }"
            tag="li"
          >
            <a>{{ $t('nav.images') }}</a>
          </router-link>
          <router-link
            :to="{ name: 'fleets' }"
            tag="li"
          >
            <a>{{ $t('nav.fleets') }}</a>
          </router-link>
          <router-link
            :to="{
              name: 'trade-routes',
              query: {
                q: $store.state.filters['trade-routes'],
              },
            }"
            tag="li"
          >
            <a>{{ $t('nav.tradeRoutes') }}</a>
          </router-link>
          <router-link
            :to="{ name: 'stats' }"
            tag="li"
          >
            <a>{{ $t('nav.stats') }}</a>
          </router-link>
          <li
            :class="{
              active: roadmapsRouteActive,
              open: roadmapMenuOpen,
            }"
            class="sub-menu"
          >
            <a @click="toggleRoadmapMenu">
              {{ $t('nav.roadmap.index') }}
              <i class="fa fa-chevron-right" />
            </a>
            <b-collapse
              id="roadmap-sub-menu"
              :visible="roadmapMenuOpen"
              tag="ul"
            >
              <router-link
                :to="{ name: 'roadmap' }"
                :class="{
                  active: roadmapRouteActive,
                }"
                active-class="router-active"
                tag="li"
              >
                <a>{{ $t('nav.roadmap.overview') }}</a>
              </router-link>
              <router-link
                :to="{ name: 'roadmap-changes' }"
                :class="{
                  active: roadmapChangesRouteActive,
                }"
                active-class="router-active"
                tag="li"
              >
                <a>{{ $t('nav.roadmap.changes') }}</a>
              </router-link>
              <router-link
                :to="{ name: 'roadmap-ships' }"
                :class="{
                  active: roadmapShipsRouteActive,
                }"
                active-class="router-active"
                tag="li"
              >
                <a>{{ $t('nav.roadmap.ships') }}</a>
              </router-link>
            </b-collapse>
          </li>
        </ul>
      </div>
    </div>
  </nav>
</template>

<script>
import QuickSearch from 'frontend/partials/Navigation/QuickSearch'
import { mapGetters } from 'vuex'

export default {
  name: 'Navigation',

  components: {
    QuickSearch,
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
      userMenuOpen: false,
      stationMenuOpen: false,
      searchQuery: null,
      roadmapMenuOpen: false,
      roadmapsRouteActive: false,
      roadmapRouteActive: false,
      roadmapChangesRouteActive: false,
      roadmapShipsRouteActive: false,
    }
  },

  computed: {
    ...mapGetters([
      'mobile',
    ]),

    ...mapGetters('app', [
      'navCollapsed',
      'isUpdateAvailable',
      'gitRevision',
    ]),

    ...mapGetters('session', [
      'currentUser',
      'citizen',
      'isAuthenticated',
    ]),

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
    documentClick(event) {
      const element = this.$refs.navigation
      const { target } = event

      if (element !== target && !element.contains(target)) {
        this.close()
      }
    },

    toggleUserMenu() {
      this.userMenuOpen = !this.userMenuOpen
    },

    toggleStationMenu() {
      this.stationMenuOpen = !this.stationMenuOpen
    },

    toggleRoadmapMenu() {
      this.roadmapMenuOpen = !this.roadmapMenuOpen
    },

    toggle() {
      this.$store.commit('app/toggleNav')
    },

    open() {
      this.$store.commit('app/openNav')
    },

    close() {
      this.$store.commit('app/closeNav')
    },

    checkRoutes() {
      const { path } = this.$route
      this.shipsRouteActive = path.includes('ships') || path.includes('manufacturers') || path.includes('components')
      this.userRouteActive = path.includes('settings')
      this.userMenuOpen = this.userRouteActive
      this.starsystemRouteActive = path.includes('starsystems') || path.includes('celestial-objects')
      this.stationsRouteActive = path.includes('stations') || path.includes('shops') || this.starsystemRouteActive
      this.stationRouteActive = path.includes('stations') && !path.includes('shops')
      this.stationMenuOpen = this.stationsRouteActive
      this.shopRouteActive = path.includes('shops')
      this.cargoRouteActive = path.includes('cargo') || path.includes('commodities')
      this.roadmapsRouteActive = path.includes('roadmap')
      this.roadmapRouteActive = path.includes('roadmap') && !path.includes('roadmap/changes') && !path.includes('roadmap/ships')
      this.roadmapMenuOpen = this.roadmapsRouteActive
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
