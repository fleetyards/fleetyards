<template>
  <section class="container fleet-detail">
    <div v-if="fleet" class="row">
      <div class="col-12 col-lg-8">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 class="sr-only">{{ fleet.name }} ({{ fleet.fid }})</h1>
      </div>
    </div>
    <br />

    <template v-if="fleet">
      <Fleetchart v-if="fleet.myFleet" :fleet="fleet" />
      <PublicFleetchart v-else :fleet="fleet" />
    </template>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'
import HangarItemsMixin from 'frontend/mixins/HangarItems'
import { publicFleetShipsRouteGuard } from 'frontend/utils/RouteGuards/Fleets'
import fleetVehiclesCollection from 'frontend/api/collections/FleetVehicles'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import fleetsCollection from 'frontend/api/collections/Fleets'
import Fleetchart from 'frontend/components/Fleets/Fleetchart'
import PublicFleetchart from 'frontend/components/Fleets/PublicFleetchart'

@Component<FleetFleetchart>({
  beforeRouteEnter: publicFleetShipsRouteGuard,
  components: {
    BreadCrumbs,
    Fleetchart,
    PublicFleetchart,
  },
  mixins: [MetaInfo, HangarItemsMixin],
})
export default class FleetFleetchart extends Vue {
  collection: FleetVehiclesCollection = fleetVehiclesCollection

  get fleet() {
    return fleetsCollection.record
  }

  get metaTitle() {
    if (!this.fleet) {
      return null
    }

    return this.fleet.name
  }

  get crumbs() {
    if (!this.fleet) {
      return []
    }

    return [
      {
        to: {
          name: 'fleet',
          params: {
            slug: this.fleet.slug,
          },
        },
        label: this.fleet.name,
      },
      {
        to: {
          name: 'fleet-ships',
          params: {
            slug: this.fleet.slug,
          },
        },
        label: this.$t('nav.fleets.ships'),
      },
    ]
  }

  mounted() {
    this.fetch()
  }

  async fetch() {
    await fleetsCollection.findBySlug(this.$route.params.slug)
  }
}
</script>
