<template>
  <div v-if="currentFleet">
    <NavItem
      :to="{ name: 'fleet', params: { slug: currentFleet.slug } }"
      :label="currentFleet.name"
      :image="currentFleet.logo"
      :active="$route.name === 'fleet'"
      exact
    />
    <template v-if="myFleet">
      <NavItem
        v-if="myFleetRole === 'admin' || myFleetRole === 'officer'"
        :to="{ name: 'fleet-members', params: { slug: currentFleet.slug } }"
        :label="$t('nav.fleets.members')"
        icon="fad fa-users"
      />
      <NavItem
        :to="{ name: 'fleet-settings', params: { slug: currentFleet.slug } }"
        :label="$t('nav.fleets.settings')"
        icon="fad fa-cogs"
      />
    </template>
  </div>
</template>

<script>
import NavItem from 'frontend/partials/Navigation/NavItem'
import FleetsMixin from 'frontend/mixins/Fleets'

export default {
  components: {
    NavItem,
  },

  mixins: [
    FleetsMixin,
  ],

  data() {
    return {
      currentFleet: null,
    }
  },

  mounted() {
    this.fetch()
    this.$comlink.$on('fleetUpdate', this.fetch)
  },

  methods: {
    async fetch() {
      const response = await this.$api.get(`fleets/${this.$route.params.slug}?nav`)

      if (!response.error) {
        this.currentFleet = response.data
      }
    },
  },
}
</script>
