<template>
  <nav
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
      <i
        v-if="isUpdateAvailable && navCollapsed"
        class="update-icon"
      />
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
              :id="`user-sub-menu`"
              :visible="userMenuOpen"
              tag="ul"
            >
              <router-link
                :to="{ name: 'settings' }"
                tag="li"
              >
                <a>{{ $t('nav.settings') }}</a>
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
        <ul v-if="isUpdateAvailable">
          <li
            v-if="isAuthenticated"
            class="divider"
          />
          <li>
            <a
              class="reload"
              @click="reload"
            >
              {{ $t('nav.reload') }}
            </a>
          </li>
          <li class="divider" />
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
              active: stationRouteActive,
              open: stationMenuOpen,
            }"
            class="sub-menu"
          >
            <a @click="toggleStationMenu">
              {{ $t('nav.stations.index') }}
              <i class="fa fa-chevron-right" />
            </a>
            <b-collapse
              :id="`stations-sub-menu`"
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
            :class="{ active: cargoRouteActive }"
            :to="{
              name: 'cargo',
              query: {
                q: $store.state.filters['cargo'],
              },
            }"
            tag="li"
          >
            <a>{{ $t('nav.cargo') }}</a>
          </router-link>
          <router-link
            :to="{ name: 'stats' }"
            tag="li"
          >
            <a>{{ $t('nav.stats') }}</a>
          </router-link>
          <router-link
            :to="{ name: 'roadmap' }"
            tag="li"
          >
            <a>{{ $t('nav.roadmap') }}</a>
          </router-link>
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
  beforeDestroy() {
    this.$store.commit('app/closeNav')
  },
  methods: {
    toggleUserMenu() {
      this.userMenuOpen = !this.userMenuOpen
    },
    toggleStationMenu() {
      this.stationMenuOpen = !this.stationMenuOpen
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
  @import './styles/index';
</style>
