<template>
  <div v-if="currentFleet">
    <NavItem
      :to="{ name: 'fleet', params: { slug: currentFleet.slug } }"
      :label="currentFleet.name"
      :image="currentFleet.logo"
      :active="$route.name === 'fleet'"
      exact
    />
    <NavItem
      v-if="currentFleet.publicFleet || currentFleet.myFleet"
      :to="{ name: 'fleet-ships', params: { slug: currentFleet.slug } }"
      :label="$t('nav.fleets.ships')"
      :active="shipsNavActive"
      icon="fad fa-starship"
    />
    <template v-if="currentFleet.myFleet">
      <NavItem
        :to="{ name: 'fleet-members', params: { slug: currentFleet.slug } }"
        :label="$t('nav.fleets.members')"
        :active="$route.name === 'fleet-members'"
        icon="fad fa-users"
      />
      <NavItem
        :to="{ name: 'fleet-stats', params: { slug: currentFleet.slug } }"
        :label="$t('nav.fleets.stats')"
        :active="$route.name === 'fleet-stats'"
        icon="fad fa-chart-bar"
      />
      <NavItem
        :to="{ name: 'fleet-settings', params: { slug: currentFleet.slug } }"
        :label="$t('nav.fleets.settings.index')"
        :active="$route.name === 'fleet-settings'"
        icon="fad fa-cogs"
      />
    </template>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import NavItem from 'frontend/core/components/Navigation/NavItem'
import fleetsCollection from 'frontend/api/collections/Fleets'

@Component<FleetNav>({
  components: {
    NavItem,
  },
})
export default class FleetNav extends Vue {
  collection: FleetsCollection = fleetsCollection

  get currentFleet(): Fleet | null {
    return this.collection.record
  }

  get shipsNavActive() {
    return ['fleet-ships', 'fleet-fleetchart'].includes(this.$route.name)
  }

  mounted() {
    this.fetch()
    this.$comlink.$on('fleet-update', this.fetch)
  }

  async fetch() {
    await this.collection.findBySlug(this.$route.params.slug)
  }
}
</script>
