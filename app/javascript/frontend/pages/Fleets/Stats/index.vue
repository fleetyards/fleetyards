<template>
  <section class="container stats">
    <div v-if="fleet && myFleet" class="row">
      <div class="col-xs-12">
        <div class="row">
          <div class="col-xs-12">
            <BreadCrumbs :crumbs="crumbs" />
            <h1>
              {{ $t('headlines.fleets.stats') }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-sm-3">
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
          <div class="col-xs-12 col-sm-3">
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
          <div class="col-xs-12 col-sm-3">
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
          <div class="col-xs-12 col-sm-3">
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
          <div class="col-xs-12 col-sm-3">
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
          <div class="col-xs-12 col-md-6">
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
          <div class="col-xs-12 col-md-6">
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
          <div class="col-xs-12 col-md-4">
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
          <div class="col-xs-12 col-md-6">
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

<script>
import { mapGetters } from 'vuex'
import MetaInfoMixin from 'frontend/mixins/MetaInfo'
import FleetsMixin from 'frontend/mixins/Fleets'
import Chart from 'frontend/components/Chart'
import Panel from 'frontend/components/Panel'
import { fleetRouteGuard } from 'frontend/utils/RouteGuards'
import BreadCrumbs from 'frontend/components/BreadCrumbs'

export default {
  name: 'Stats',

  beforeRouteEnter: fleetRouteGuard,

  components: {
    Chart,
    Panel,
    BreadCrumbs,
  },

  mixins: [MetaInfoMixin, FleetsMixin],

  data() {
    return {
      quickStats: null,
      fleet: null,
    }
  },

  computed: {
    ...mapGetters('session', ['currentUser']),

    sid() {
      return this.$route.params.slug
    },

    totalMemberCount() {
      if (!this.quickStats) {
        return 0
      }

      return this.quickStats.totalMembers
    },

    totalShipCount() {
      if (!this.quickStats) {
        return 0
      }

      return this.quickStats.totalShips
    },

    minCrew() {
      if (!this.quickStats) {
        return this.$toNumber(0, 'people')
      }

      return this.$toNumber(this.quickStats.metrics.totalMinCrew, 'people')
    },

    maxCrew() {
      if (!this.quickStats) {
        return this.$toNumber(0, 'people')
      }

      return this.$toNumber(this.quickStats.metrics.totalMaxCrew, 'people')
    },

    totalCargo() {
      if (!this.quickStats) {
        return this.$toNumber(0, 'cargo')
      }

      return this.$toNumber(this.quickStats.metrics.totalCargo, 'cargo')
    },

    crumbs() {
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
    },

    metaTitle() {
      if (!this.fleet) {
        return null
      }

      return this.$t('title.fleets.stats', { fleet: this.fleet.name })
    },
  },

  methods: {
    async loadQuickStats() {
      const response = await this.$api.get(`fleets/${this.sid}/quick-stats`)
      if (!response.error) {
        this.quickStats = response.data
      }
    },

    async loadModelsByClassification() {
      const response = await this.$api.get(
        `fleets/${this.sid}/stats/models-by-classification`,
      )
      if (!response.error) {
        return response.data
      }
      return []
    },

    async loadModelsBySize() {
      const response = await this.$api.get(
        `fleets/${this.sid}/stats/models-by-size`,
      )
      if (!response.error) {
        return response.data
      }
      return []
    },

    async loadModelsByManufacturer() {
      const response = await this.$api.get(
        `fleets/${this.sid}/stats/models-by-manufacturer`,
      )
      if (!response.error) {
        return response.data
      }
      return []
    },

    async loadModelsByProductionStatus() {
      const response = await this.$api.get(
        `fleets/${this.sid}/stats/models-by-production-status`,
      )
      if (!response.error) {
        return response.data
      }
      return []
    },
  },
}
</script>
