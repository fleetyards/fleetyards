<template>
  <NavItem
    :label="$t('nav.stations.index')"
    :submenu-active="active"
    menu-key="stations-menu"
    icon="fad fa-planet-ringed"
  >
    <template slot="submenu">
      <NavItem
        :to="{ name: 'stations' }"
        :label="$t('nav.stations.overview')"
        icon="fad fa-planet-ringed"
      />
      <NavItem
        :to="{ name: 'starsystems' }"
        :label="$t('nav.stations.starsystems')"
        icon="fad fa-solar-system"
      />
      <NavItem :divider="true" />
      <NavItem
        :to="{ name: 'shops' }"
        :label="$t('nav.stations.shops')"
        icon="fad fa-store-alt"
      />
    </template>
  </NavItem>
</template>

<script>
import NavItem from 'frontend/core/components/Navigation/NavItem'
import NavigationMixin from 'frontend/mixins/Navigation'

export default {
  components: {
    NavItem,
  },

  mixins: [NavigationMixin],

  computed: {
    active() {
      return [
        'stations',
        'station',
        'shops',
        'shop',
        'starsystems',
        'starsystem',
        'celestial-object',
        'station-images',
      ].includes(this.$route.name)
    },
  },
}
</script>
