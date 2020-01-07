<template>
  <NavItem
    :label="$t('nav.roadmap.index')"
    :submenu-active="active"
    menu-key="roadmap-menu"
    icon="fad fa-tasks-alt"
  >
    <template slot="submenu">
      <NavItem
        :to="{ name: 'roadmap' }"
        :label="$t('nav.stations.overview')"
        icon="fad fa-tasks-alt"
        :active="$route.name === 'roadmap'"
        exact
      />
      <NavItem
        :to="{ name: 'roadmap-changes' }"
        :label="$t('nav.roadmap.changes')"
        icon="fad fa-tasks"
      />
      <NavItem divider />
      <NavItem
        :to="{ name: 'roadmap-ships' }"
        :label="$t('nav.roadmap.ships')"
        icon="fad fa-rocket-launch"
      />
    </template>
  </NavItem>
</template>

<script>
import NavItem from 'frontend/partials/Navigation/NavItem'
import NavigationMixin from 'frontend/mixins/Navigation'

export default {
  components: {
    NavItem,
  },

  mixins: [
    NavigationMixin,
  ],

  computed: {
    active() {
      return [
        'roadmap', 'roadmap-changes', 'roadmap-ships',
      ].includes(this.$route.name)
    },
  },
}
</script>
