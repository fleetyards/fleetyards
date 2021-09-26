<template>
  <div>
    <div class="row">
      <div class="col-12">
        <ModelClassLabels
          v-if="fleetStats"
          :label="$t('labels.fleet.classes')"
          :count-data="fleetStats.classifications"
          filter-key="classificationIn"
        />
      </div>
    </div>

    <div v-if="fleetStats && fleetStats.metrics && !mobile" class="row">
      <div class="col-12 fleet-metrics metrics-block" @click="toggleMoney">
        <div v-if="money" class="metrics-item">
          <div class="metrics-label">
            {{ $t('labels.hangarMetrics.totalMoney') }}:
          </div>
          <div class="metrics-value">
            {{ $toDollar(fleetStats.metrics.totalMoney) }}
          </div>
        </div>
        <div class="metrics-item">
          <div class="metrics-label">
            {{ $t('labels.hangarMetrics.total') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(fleetStats.total, 'ships') }}
          </div>
        </div>
        <div class="metrics-item">
          <div class="metrics-label">
            {{ $t('labels.hangarMetrics.totalMinCrew') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(fleetStats.metrics.totalMinCrew, 'people') }}
          </div>
        </div>
        <div class="metrics-item">
          <div class="metrics-label">
            {{ $t('labels.hangarMetrics.totalMaxCrew') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(fleetStats.metrics.totalMaxCrew, 'people') }}
          </div>
        </div>
        <div class="metrics-item">
          <div class="metrics-label">
            {{ $t('labels.hangarMetrics.totalCargo') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(fleetStats.metrics.totalCargo, 'cargo') }}
          </div>
        </div>
      </div>
    </div>

    <FilteredList
      key="fleet-ships"
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :params="routeParams"
      :hash="$route.hash"
      :paginated="true"
    >
      <template slot="actions">
        <BtnDropdown size="small">
          <template v-if="mobile">
            <Btn
              :to="{
                name: 'fleet-fleetchart',
                params: { slug: fleet.slug },
              }"
              size="small"
              variant="dropdown"
            >
              <i class="fad fa-starship" />
              <span>{{ $t('labels.fleetchart') }}</span>
            </Btn>

            <Btn
              v-if="fleet.publicFleet"
              size="small"
              variant="dropdown"
              @click.native="copyPublicUrl"
            >
              <i class="fad fa-share-square" />
              <span>{{ $t('actions.copyPublicUrl') }}</span>
            </Btn>

            <hr />
          </template>
          <Btn
            :active="detailsVisible"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="dropdown"
            @click.native="toggleDetails"
          >
            <i class="fad fa-info-square" />
            <span>{{ toggleDetailsTooltip }}</span>
          </Btn>

          <Btn size="small" variant="dropdown" @click.native="toggleGrouped">
            <template v-if="grouped">
              <i class="fas fa-square" />
              <span>{{ $t('actions.ungrouped') }}</span>
            </template>
            <template v-else>
              <i class="fas fa-th-large" />
              <span>{{ $t('actions.groupedByModel') }}</span>
            </template>
          </Btn>
        </BtnDropdown>
      </template>

      <FleetVehiclesFilterForm slot="filter" />

      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          :records="records"
          :loading="loading"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <FleetVehiclePanel
              :fleet-vehicle="record"
              :details="detailsVisible"
            />
          </template>
        </FilteredGrid>
      </template>
    </FilteredList>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import FilteredList from 'frontend/core/components/FilteredList'
import FilteredGrid from 'frontend/core/components/FilteredGrid'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import FleetVehiclePanel from 'frontend/components/Fleets/VehiclePanel'
import FleetVehiclesFilterForm from 'frontend/components/Fleets/FilterForm'
import FleetModelsFilterForm from 'frontend/components/Models/FilterForm'
import ModelClassLabels from 'frontend/components/Models/ClassLabels'
import AddonsModal from 'frontend/components/Vehicles/AddonsModal'
import fleetVehiclesCollection from 'frontend/api/collections/FleetVehicles'
import debounce from 'lodash.debounce'

@Component<FleetShipsList>({
  components: {
    Btn,
    BtnDropdown,
    FilteredList,
    FilteredGrid,
    FleetVehiclePanel,
    ModelClassLabels,
    AddonsModal,
    FleetVehiclesFilterForm,
    FleetModelsFilterForm,
  },
})
export default class FleetShipsList extends Vue {
  collection: FleetVehiclesCollection = fleetVehiclesCollection

  fleetVehiclesChannel = null

  @Prop({ required: true }) fleet: Fleet

  @Prop({ required: true }) copyPublicUrl: Function

  @Getter('grouped', { namespace: 'fleet' }) grouped

  @Getter('money', { namespace: 'fleet' }) money

  @Getter('detailsVisible', { namespace: 'fleet' }) detailsVisible

  @Getter('mobile') mobile

  get fleetStats() {
    return this.collection.stats
  }

  get toggleDetailsTooltip() {
    if (this.detailsVisible) {
      return this.$t('actions.hideDetails')
    }
    return this.$t('actions.showDetails')
  }

  get routeParams() {
    return {
      ...this.$route.params,
      grouped: this.grouped,
    }
  }

  get filters() {
    return {
      slug: this.fleet.slug,
      filters: this.$route.query.q,
      grouped: this.grouped,
      page: this.$route.query.page,
    }
  }

  @Watch('grouped')
  onGroupedChange() {
    this.fetch()
  }

  @Watch('$route')
  onRouteChange() {
    this.fetchStats()
  }

  @Watch('fleet')
  onFleetChange() {
    this.fetchStats()
  }

  mounted() {
    this.fetchStats()
    this.setupUpdates()
  }

  toggleDetails() {
    this.$store.dispatch('fleet/toggleDetails')
  }

  toggleGrouped() {
    this.$store.dispatch('fleet/toggleGrouped')
  }

  toggleMoney() {
    this.$store.dispatch('fleet/toggleMoney')
  }

  setupUpdates() {
    if (this.fleetVehiclesChannel) {
      this.fleetVehiclesChannel.unsubscribe()
    }

    this.fleetVehiclesChannel = this.$cable.consumer.subscriptions.create(
      {
        channel: 'FleetVehiclesChannel',
      },
      {
        received: debounce(this.fetch, 500),
      },
    )
  }

  async fetch() {
    await this.collection.findAll(this.filters)
    await this.fetchStats()
  }

  async fetchStats() {
    await this.collection.findStats(this.filters)
  }
}
</script>

<style lang="scss" scoped>
.fleet-metrics {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
  cursor: pointer;

  .metrics-label,
  .metrics-value {
    display: inline-block;
  }
}
</style>
