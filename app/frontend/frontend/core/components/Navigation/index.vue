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
          <NavItem class="logo-menu">
            <img
              v-lazy="require('@/images/favicon-small.png')"
              class="logo-menu-image"
              alt="logo"
            />
            <span v-if="!slim" class="logo-menu-label">
              {{ $t('app') }}
            </span>
          </NavItem>
          <FleetNav v-if="isFleetRoute" />
          <template v-else>
            <NavItem
              :to="{ name: 'home' }"
              :label="$t('nav.home')"
              icon="fad fa-home-alt"
              :exact="true"
            />
            <NavItem
              v-if="isAuthenticated || !hangarPreview"
              :to="{
                name: 'hangar',
                query: filterFor('hangar'),
              }"
              :label="$t('nav.hangar')"
              icon="fad fa-warehouse"
            />
            <NavItem
              v-else
              :to="{ name: 'hangar-preview' }"
              :label="$t('nav.hangar')"
              icon="fal fa-warehouse"
            />
            <NavItem
              :to="{
                name: 'models',
                query: filterFor('models'),
              }"
              :label="$t('nav.models.index')"
              :active="isModelRoute"
              icon="fad fa-starship"
            />
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
            <NavItem
              :to="{ name: 'roadmap' }"
              :label="$t('nav.roadmap.index')"
              icon="fad fa-tasks-alt"
              :active="isRoadmapRoute"
            />
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
import NavItem from '@/frontend/core/components/Navigation/NavItem/index.vue'
import FleetNav from '@/frontend/core/components/Navigation/FleetNav/index.vue'
import FleetsNav from '@/frontend/core/components/Navigation/FleetsNav/index.vue'
import StationsNav from '@/frontend/core/components/Navigation/StationsNav/index.vue'
import NavFooter from '@/frontend/core/components/Navigation/NavFooter/index.vue'
import NavigationMixin from '@/frontend/mixins/Navigation'
import { isFleetRoute } from '@/frontend/utils/Routes/Fleets'

@Component<Navigation>({
  components: {
    NavItem,
    FleetNav,
    FleetsNav,
    StationsNav,
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
    return isFleetRoute(this.$route.name)
  }

  get isRoadmapRoute() {
    if (!this.$route.name) {
      return false
    }

    return this.$route.name.includes('roadmap')
  }

  get isModelRoute() {
    if (!this.$route.name) {
      return false
    }

    return this.$route.name.includes('model')
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
