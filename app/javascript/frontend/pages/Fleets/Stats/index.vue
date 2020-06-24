<template>
  <section class="container stats">
    <div v-if="fleet" class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <BreadCrumbs :crumbs="crumbs" />
            <h1>
              {{ $t('headlines.fleets.stats') }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-user fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ totalMemberCount }}
                  <div class="panel-box-text-info">
                    {{ $t('labels.stats.quickStats.totalMembers') }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
          <div class="col-12 col-md-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-rocket fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ totalShipCount }}
                  <div class="panel-box-text-info">
                    {{ $t('labels.stats.quickStats.totalShips') }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
          <div class="col-12 col-md-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-user fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ minCrew }}
                  <div class="panel-box-text-info">
                    {{ $t('labels.hangarMetrics.totalMinCrew') }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
          <div class="col-12 col-md-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-users fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ maxCrew }}
                  <div class="panel-box-text-info">
                    {{ $t('labels.hangarMetrics.totalMaxCrew') }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
          <div class="col-12 col-md-3">
            <Panel variant="primary">
              <div class="panel-box">
                <div class="panel-box-icon">
                  <i class="fad fa-box-open fa-4x" />
                </div>
                <div class="panel-box-text">
                  {{ totalCargo }}
                  <div class="panel-box-text-info">
                    {{ $t('labels.hangarMetrics.totalCargo') }}
                  </div>
                </div>
              </div>
            </Panel>
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-lg-6">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsByClassification') }}
                </h2>
              </div>
              <Chart
                key="models-by-classification"
                :load-data="loadModelsByClassification"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
          <div class="col-12 col-lg-6">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsBySize') }}
                </h2>
              </div>
              <Chart
                key="models-by-size"
                :load-data="loadModelsBySize"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-lg-4">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsByProductionStatus') }}
                </h2>
              </div>
              <Chart
                key="models-by-production-status"
                :load-data="loadModelsByProductionStatus"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
          <div class="col-12 col-lg-6">
            <Panel>
              <div class="panel-heading">
                <h2 class="panel-title">
                  {{ $t('labels.stats.modelsByManufacturer') }}
                </h2>
              </div>
              <Chart
                key="models-by-manufacturer"
                :load-data="loadModelsByManufacturer"
                tooltip-type="ship-pie"
                type="pie"
              />
            </Panel>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import MetaInfoMixin from 'frontend/mixins/MetaInfo'
import Chart from 'frontend/components/Chart'
import Panel from 'frontend/components/Panel'
import { fleetRouteGuard } from 'frontend/utils/RouteGuards'
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import fleetsCollection from 'frontend/collections/Fleets'
import vehiclesCollection from 'frontend/collections/FleetVehicles'
import membersCollection from 'frontend/collections/FleetMembers'

@Component({
  beforeRouteEnter: fleetRouteGuard,
  components: {
    Chart,
    Panel,
    BreadCrumbs,
  },
  mixins: [MetaInfoMixin],
})
export default class FleetStats extends Vue {
  fleet: Fleet | null = null

  collection: FleetsCollection = fleetsCollection

  vehiclesCollection: FleetVehiclesCollection = vehiclesCollection

  membersCollection: FleetMembersCollection = membersCollection

  get slug() {
    return this.$route.params.slug
  }

  get vehicleStats() {
    return this.vehiclesCollection.stats
  }

  get memberStats() {
    return this.membersCollection.stats
  }

  get totalMemberCount() {
    if (!this.memberStats) {
      return 0
    }

    return this.memberStats.total
  }

  get totalShipCount() {
    if (!this.vehicleStats) {
      return 0
    }

    return this.vehicleStats.total
  }

  get minCrew() {
    if (!this.vehicleStats) {
      return this.$toNumber(0, 'people')
    }

    return this.$toNumber(this.vehicleStats.metrics.totalMinCrew, 'people')
  }

  get maxCrew() {
    if (!this.vehicleStats) {
      return this.$toNumber(0, 'people')
    }

    return this.$toNumber(this.vehicleStats.metrics.totalMaxCrew, 'people')
  }

  get totalCargo() {
    if (!this.vehicleStats) {
      return this.$toNumber(0, 'cargo')
    }

    return this.$toNumber(this.vehicleStats.metrics.totalCargo, 'cargo')
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
    ]
  }

  get metaTitle() {
    if (!this.fleet) {
      return null
    }

    return this.$t('title.fleets.stats', { fleet: this.fleet.name })
  }

  created() {
    this.loadQuickStats()
  }

  loadQuickStats() {
    this.vehiclesCollection.findStats({ slug: this.slug })
    this.membersCollection.findStats({ slug: this.slug })
  }

  loadModelsByClassification() {
    return this.collection.findModelsByClassificationBySlug(this.slug)
  }

  loadModelsBySize() {
    return this.collection.findModelsBySizeBySlug(this.slug)
  }

  loadModelsByManufacturer() {
    return this.collection.findModelsByManufacturerBySlug(this.slug)
  }

  loadModelsByProductionStatus() {
    return this.collection.findModelsByProductionStatusBySlug(this.slug)
  }
}
</script>
