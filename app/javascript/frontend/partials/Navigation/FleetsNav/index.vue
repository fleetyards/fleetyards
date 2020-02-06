<template>
  <NavItem
    :label="$t('nav.fleets.index')"
    :submenu-active="active"
    menu-key="fleets-menu"
    icon="fad fa-planet-ringed"
  >
    <span
      :class="{
        'fleets-nav-item-icon-slim': slim,
      }"
      class="fleets-nav-item-icon"
    >
      <i class="fad fa-rocket-launch" />
      <i class="fad fa-rocket-launch" />
    </span>
    <transition name="fade-nav">
      <span v-if="!slim">{{ $t('nav.fleets.index') }}</span>
    </transition>
    <template slot="submenu">
      <NavItem
        v-for="fleet in myFleets"
        :key="fleet.slug"
        :to="{ name: 'fleet', params: { slug: fleet.slug } }"
        :label="fleet.name"
        :image="fleet.logo"
      />
      <NavItem
        v-if="isAuthenticated && invites.length"
        :to="{ name: 'fleet-invites' }"
        :label="$t('nav.fleets.invites')"
        icon="fad fa-envelope-open-text"
      />
      <NavItem
        v-if="isAuthenticated || !fleetPreview"
        :to="{ name: 'fleet-add' }"
        :label="$t('nav.fleets.add')"
        icon="fal fa-plus"
      />
      <NavItem
        v-else
        :to="{ name: 'fleet-preview' }"
        :label="$t('nav.fleets.add')"
        icon="fal fa-plus"
      />
    </template>
  </NavItem>
</template>

<script>
import { mapGetters } from 'vuex'
import NavItem from 'frontend/partials/Navigation/NavItem'
import NavigationMixin from 'frontend/mixins/Navigation'
import FleetsMixin from 'frontend/mixins/Fleets'

export default {
  components: {
    NavItem,
  },

  mixins: [NavigationMixin, FleetsMixin],

  data() {
    return {
      invites: [],
    }
  },

  computed: {
    ...mapGetters('fleet', {
      fleetPreview: 'preview',
    }),

    active() {
      return ['fleets', 'fleet-add', 'fleet-preview', 'fleet-invites'].includes(
        this.$route.name,
      )
    },
  },

  watch: {
    $route() {
      this.fetch()
    },
  },

  mounted() {
    this.fetch()
  },

  methods: {
    async fetch() {
      if (!this.isAuthenticated) {
        return
      }

      const response = await this.$api.get('fleets/invites?nav')

      if (!response.error) {
        this.invites = response.data
      }
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
