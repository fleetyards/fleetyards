<template>
  <nav
    :class="{
      'navbar-visble': !navbarCollapsed,
    }"
    class="navbar navbar-default navbar-fixed-top"
    role="navigation"
  >
    <div class="container">
      <div class="navbar-header">
        <button
          :class="{
            collapsed: navbarCollapsed,
          }"
          class="navbar-toggle"
          type="button"
          aria-label="Toggle Navigation"
          @click.stop.prevent="toggle"
        >
          <span class="sr-only">Toggle Navigation</span>
          <span class="icon-bar top-bar" />
          <span class="icon-bar middle-bar" />
          <span class="icon-bar bottom-bar" />
        </button>
        <router-link
          :to="{ name: 'home' }"
          class="navbar-brand"
          exact
        >
          {{ t('app') }}
        </router-link>
      </div>
      <div
        :class="{
          in: !navbarCollapsed,
        }"
        class="collapse navbar-collapse"
      >
        <div class="navbar-wrapper">
          <div
            v-if="mobile"
            class="navbar-form"
          >
            <Btn
              small
              inline
              @click.native="reload"
            >
              {{ t('actions.reload') }}
            </Btn>
          </div>
          <ul class="nav navbar-nav">
            <router-link
              :to="{ name: 'home' }"
              tag="li"
              exact
            >
              <a>{{ t('nav.home') }}</a>
            </router-link>
            <router-link
              :to="{ name: 'models' }"
              tag="li"
            >
              <a>{{ t('nav.models') }}</a>
            </router-link>
            <router-link
              :to="{ name: 'hangar' }"
              tag="li"
            >
              <a>{{ t('nav.hangar') }}</a>
            </router-link>
            <router-link
              :to="{ name: 'images' }"
              tag="li"
            >
              <a>{{ t('nav.images') }}</a>
            </router-link>
            <router-link
              :to="{ name: 'fleets' }"
              tag="li"
            >
              <a>{{ t('nav.fleets') }}</a>
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
              <a>{{ t('nav.cargo') }}</a>
            </router-link>
          </ul>
          <div
            :class="{
              'navbar-form-placeholder': !updateAvailable
            }"
            class="navbar-form"
          >
            <transition
              name="fade"
              mode="out-in"
              appear
            >
              <div
                v-if="updateAvailable"
                class="text-right"
              >
                <Btn
                  class="update"
                  primary
                  inline
                  small
                  @click.native="upgrade"
                >
                  <i class="fal fa-sync" />
                  {{ t('actions.upgrade') }}
                </Btn>
              </div>
            </transition>
          </div>
          <ul
            v-if="!isAuthenticated"
            class="nav navbar-nav navbar-right"
          >
            <router-link
              :to="{ name: 'signup' }"
              tag="li"
            >
              <a>{{ t('nav.signUp') }}</a>
            </router-link>
            <router-link
              :to="{ name: 'login' }"
              tag="li"
            >
              <a>{{ t('nav.login') }}</a>
            </router-link>
          </ul>
          <ul
            v-if="isAuthenticated && currentUser"
            class="nav navbar-nav navbar-right"
          >
            <li
              :class="{
                'open': userMenuOpen,
                'active': userRouteActive
              }"
              class="dropdown user-menu"
            >
              <a
                class="dropdown-toggle"
                @click="toggleUserMenu"
              >
                <span
                  v-tooltip="t('labels.rsiVerified')"
                  v-if="currentUser.rsiVerified"
                  class="verified"
                >
                  <i class="fa fa-check" />
                </span>
                <img
                  v-tooltip.left="currentUser.username"
                  v-if="citizen"
                  :src="citizen.avatar"
                  class="avatar"
                  alt="avatar"
                  width="36"
                  height="36"
                >
                <span
                  v-tooltip.left="currentUser.username"
                  v-if="!citizen || !citizen.avatar"
                  class="avatar"
                >
                  <i class="fa fa-user" />
                </span>
                <span class="username">{{ currentUser.username }}</span>
              </a>
              <ul class="dropdown-menu navbar-right">
                <router-link
                  :to="{ name: 'settings' }"
                  tag="li"
                >
                  <a>{{ t('nav.settings') }}</a>
                </router-link>
                <li class="divider" />
                <li v-if="currentUser.rsiHandle">
                  <a
                    :href="`https://robertsspaceindustries.com/citizens/${currentUser.rsiHandle}`"
                    target="_blank"
                    rel="noopener"
                  >
                    {{ t('nav.rsiProfile') }}
                  </a>
                </li>
                <li class="divider" />
                <li>
                  <a @click="logout">{{ t('nav.logout') }}</a>
                </li>
              </ul>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </nav>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Btn from 'frontend/components/Btn'
import { mapGetters } from 'vuex'

export default {
  components: {
    Btn,
  },
  mixins: [I18n],
  data() {
    return {
      shipsRouteActive: false,
      userRouteActive: false,
      cargoRouteActive: false,
      userMenuOpen: false,
      searchQuery: null,
    }
  },
  computed: {
    ...mapGetters([
      'currentUser',
      'citizen',
      'isAuthenticated',
      'navbarCollapsed',
      'updateAvailable',
      'mobile',
    ]),
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
    this.$store.commit('closeNavbar')
  },
  methods: {
    toggleUserMenu() {
      this.userMenuOpen = !this.userMenuOpen
    },
    toggle() {
      this.$store.commit('toggleNavbar')
    },
    close() {
      this.userMenuOpen = false
      this.$store.commit('closeNavbar')
    },
    checkRoutes() {
      const { path } = this.$route
      this.shipsRouteActive = path.includes('ships') || path.includes('manufacturers') || path.includes('components')
      this.userRouteActive = path.includes('settings')
      this.cargoRouteActive = path.includes('cargo') || path.includes('commodities')
    },
    async logout() {
      await this.$store.dispatch('logout')
    },
    upgrade() {
      this.$store.commit('setUpdateAvailable', false)
      this.reload()
    },
    reload() {
      this.close()
      window.location.reload(true)
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
