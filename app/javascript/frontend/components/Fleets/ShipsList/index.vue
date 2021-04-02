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
            <ModelPanel
              v-if="record.model"
              :model="record.model"
              :details="detailsVisible"
              :vehicle="record"
              :show-owner="true"
            />
            <ModelPanel
              v-else
              :model="record"
              :details="detailsVisible"
              :vehicles="record.vehicles"
              :show-owner="true"
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
import ModelPanel from 'frontend/components/Models/Panel'
import FleetVehiclesFilterForm from 'frontend/components/Fleets/FilterForm'
import FleetModelsFilterForm from 'frontend/components/Models/FilterForm'
import ModelClassLabels from 'frontend/components/Models/ClassLabels'
import AddonsModal from 'frontend/components/Vehicles/AddonsModal'
import fleetVehiclesCollection from 'frontend/api/collections/FleetVehicles'

@Component<FleetShipsList>({
  components: {
    Btn,
    BtnDropdown,
    FilteredList,
    FilteredGrid,
    ModelPanel,
    ModelClassLabels,
    AddonsModal,
    FleetVehiclesFilterForm,
    FleetModelsFilterForm,
  },
})
export default class FleetShipsList extends Vue {
  collection: FleetVehiclesCollection = fleetVehiclesCollection

  @Prop({ required: true }) fleet: Fleet

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
    this.collection.findAll(this.filters)
    this.fetchStats()
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
