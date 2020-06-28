<template>
  <div v-if="currentFleet">
    <NavItem
      :to="{ name: 'fleet', params: { slug: currentFleet.slug } }"
      :label="currentFleet.name"
      :image="currentFleet.logo"
      :active="$route.name === 'fleet'"
      exact
    />
    <template v-if="currentFleet.myFleet">
      <NavItem
        :to="{ name: 'fleet-members', params: { slug: currentFleet.slug } }"
        :label="$t('nav.fleets.members')"
        icon="fad fa-users"
      />
      <NavItem
        :to="{ name: 'fleet-settings', params: { slug: currentFleet.slug } }"
        :label="$t('nav.fleets.settings.index')"
        icon="fad fa-cogs"
      />
    </template>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import NavItem from 'frontend/partials/Navigation/NavItem'
import fleetsCollection from 'frontend/collections/Fleets'

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

  mounted() {
    this.fetch()
    this.$comlink.$on('fleetUpdate', this.fetch)
  }

  async fetch() {
    await this.collection.findBySlug(this.$route.params.slug)
  }
}
</script>
