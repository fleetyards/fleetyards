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
        :exact="true"
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

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import NavItem from 'frontend/core/components/Navigation/NavItem'
import NavigationMixin from 'frontend/mixins/Navigation'

@Component<ShipsNav>({
  components: {
    NavItem,
  },
  mixins: [NavigationMixin],
})
export default class RoadmapNav extends Vue {
  get active() {
    return ['roadmap', 'roadmap-changes', 'roadmap-ships'].includes(
      this.$route.name,
    )
  }
}
</script>
