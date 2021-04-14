<template>
  <nav
    ref="navigation"
    :class="{
      'visible': !navCollapsed,
      'nav-slim': slim,
    }"
    role="navigation"
  >
    <div
      :class="{
        'nav-container-slim': slim,
      }"
      class="nav-container"
    >
      <div class="nav-container-inner">
        <ul>
          <UserNav v-if="isAuthenticated" />
          <NavItem
            v-else
            key="user-menu-guest"
            :to="{ name: 'login' }"
            :label="$t('nav.login')"
            icon="fad fa-sign-in"
          />
          <NavItem
            :to="{ name: 'home' }"
            :label="$t('nav.home')"
            :icon="isFleetRoute ? 'fal fa-chevron-left' : 'fad fa-home-alt'"
            :exact="true"
          />
          <FleetNav v-if="isFleetRoute" />
          <template v-else>
            <NavItem
              v-if="isAuthenticated || !hangarPreview"
              :to="{
                name: 'hangar',
                query: filterFor('hangar'),
              }"
              :label="$t('nav.hangar')"
              icon="fad fa-bookmark"
            />
            <NavItem
              v-else
              :to="{ name: 'hangar-preview' }"
              :label="$t('nav.hangar')"
              icon="fal fa-bookmark"
            />
            <ShipsNav />
            <StationsNav />
            <FleetsNav />
            <NavItem
              :to="{ name: 'images' }"
              :label="$t('nav.images')"
              icon="fad fa-images"
            />
            <NavItem
              :to="{
                name: 'trade-routes',
                query: filterFor('trade-routes'),
              }"
              :label="$t('nav.tradeRoutes')"
              icon="fad fa-pallet-alt"
            />
            <RoadmapNav />
            <NavItem
              :to="{ name: 'stats' }"
              :label="$t('nav.stats')"
              icon="fad fa-chart-bar"
            />
          </template>
        </ul>
        <NavFooter />
      </div>
    </div>
  </nav>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import NavItem from 'frontend/core/components/Navigation/NavItem'
import UserNav from 'frontend/core/components/Navigation/UserNav'
import FleetNav from 'frontend/core/components/Navigation/FleetNav'
import FleetsNav from 'frontend/core/components/Navigation/FleetsNav'
import ShipsNav from 'frontend/core/components/Navigation/ShipsNav'
import StationsNav from 'frontend/core/components/Navigation/StationsNav'
import RoadmapNav from 'frontend/core/components/Navigation/RoadmapNav'
import NavFooter from 'frontend/core/components/Navigation/NavFooter'
import NavigationMixin from 'frontend/mixins/Navigation'

@Component<Navigation>({
  components: {
    NavItem,
    UserNav,
    FleetNav,
    FleetsNav,
    ShipsNav,
    StationsNav,
    RoadmapNav,
    NavFooter,
  },
  mixins: [NavigationMixin],
})
export default class Navigation extends Vue {
  searchQuery = null

  @Getter('filters') filters

  @Getter('navCollapsed', { namespace: 'app' }) navCollapsed

  @Getter('isUpdateAvailable', { namespace: 'app' }) isUpdateAvailable

  @Getter('preview', { namespace: 'hangar' }) hangarPreview

  get isFleetRoute() {
    return [
      'fleet',
      'fleet-ships',
      'fleet-members',
      'fleet-stats',
      'fleet-fleetchart',
      'fleet-settings',
      'fleet-settings-fleet',
      'fleet-settings-membership',
    ].includes(this.$route.name)
  }

  @Watch('$route')
  onRouteChange() {
    this.close()
  }

  created() {
    document.addEventListener('click', this.documentClick)
  }

  destroyed() {
    document.removeEventListener('click', this.documentClick)
  }

  beforeDestroy() {
    this.close()
  }

  filterFor(route) {
    // // TODO: disabled until vue-router supports navigation to same route
    // return null
    if (!this.filters[route]) {
      return null
    }

    return {
      q: this.filters[route],
    }
  }

  documentClick(event) {
    const element = this.$refs.navigation
    const { target } = event

    if (element !== target && !element.contains(target)) {
      this.close()
    }
  }

  open() {
    this.$store.commit('app/openNav')
  }

  close() {
    this.$store.commit('app/closeNav')
  }

  reload() {
    this.close()

    window.location.reload(true)
  }
}
</script>
