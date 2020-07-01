<template>
  <section class="container fleet-detail">
    <div v-if="fleet" class="row">
      <div class="col-12 col-lg-8">
        <h1>
          <Avatar
            v-if="fleet.logo"
            :avatar="fleet.logo"
            :transparent="!!fleet.logo"
            icon="fad fa-image"
          />
          {{ fleet.name }} ({{ fleet.fid }})
        </h1>
      </div>
      <div class="col-12 col-lg-4 fleet-links">
        <a
          v-if="fleet.homepage"
          v-tooltip="$t('labels.homepage')"
          :href="fleet.homepage"
          target="_blank"
          rel="noopener"
        >
          <i class="fad fa-home" />
        </a>
        <a
          v-if="fleet.rsiSid"
          v-tooltip="$t('nav.rsiProfile')"
          :href="`https://robertsspaceindustries.com/orgs/${fleet.rsiSid}`"
          target="_blank"
          rel="noopener"
        >
          <i class="icon icon-rsi" />
        </a>
        <a
          v-if="fleet.guilded"
          v-tooltip="$t('labels.guilded')"
          :href="fleet.guilded"
          target="_blank"
          rel="noopener"
        >
          <i class="icon icon-guilded" />
        </a>
        <a
          v-if="fleet.discord"
          v-tooltip="$t('labels.discord')"
          :href="fleet.discord"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-discord" />
        </a>
        <a
          v-if="fleet.ts"
          v-tooltip="$t('labels.fleet.ts')"
          :href="fleet.ts"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-teamspeak" />
        </a>
        <a
          v-if="fleet.youtube"
          v-tooltip="$t('labels.youtube')"
          :href="fleet.youtube"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-youtube" />
        </a>
        <a
          v-if="fleet.twitch"
          v-tooltip="$t('labels.twitch')"
          :href="fleet.twitch"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-twitch" />
        </a>
      </div>
    </div>
    <div v-if="fleet && fleet.myFleet" class="row">
      <div class="col-12 col-lg-8">
        <ModelClassLabels
          v-if="fleetStats"
          :label="$t('labels.fleet.classes')"
          :count-data="fleetStats.classifications"
          filter-key="classificationIn"
        />
      </div>
      <div class="col-12 col-lg-4">
        <div class="page-actions">
          <Btn
            :to="{
              name: 'fleet-fleetchart',
              params: { slug: $route.params.slug },
            }"
          >
            <i class="fad fa-starship" />
            {{ $t('labels.fleetchart') }}
          </Btn>
          <Btn
            v-tooltip="$t('labels.hangarStats')"
            :to="{
              name: 'fleet-stats',
              params: { slug: $route.params.slug },
            }"
          >
            <i class="fal fa-chart-bar" />
          </Btn>
        </div>
      </div>
    </div>

    <div
      v-if="
        fleetStats && fleetStats.metrics && !mobile && fleet && fleet.myFleet
      "
      class="row"
    >
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
      v-if="fleet && fleet.myFleet"
      :collection="vehiclesCollection"
      :name="$route.name"
      :route-query="$route.query"
      :params="routeParams"
      :hash="$route.hash"
      :paginated="true"
    >
      <template slot="actions">
        <BtnDropdown size="small">
          <template v-if="mobile">
            <Btn :to="{ name: 'fleet-stats' }" size="small" variant="link">
              <i class="fad fa-chart-bar" />
              {{ $t('labels.fleetStats') }}
            </Btn>

            <hr />
          </template>

          <Btn
            :active="detailsVisible"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="link"
            @click.native="toggleDetails"
          >
            <i class="fad fa-info-square" />
            {{ toggleDetailsTooltip }}
          </Btn>

          <Btn size="small" variant="link" @click.native="toggleGrouped">
            <template v-if="grouped">
              <i class="fas fa-square" />
              {{ $t('actions.ungrouped') }}
            </template>
            <template v-else>
              <i class="fas fa-th-large" />
              {{ $t('actions.groupedByModel') }}
            </template>
          </Btn>
        </BtnDropdown>
      </template>

      <FleetVehiclesFilterForm slot="filter" />

      <template v-slot:record="{ record }">
        <ModelPanel
          v-if="record.model"
          :model="record.model"
          :details="detailsVisible"
          :on-addons="showAddonsModal"
        />
        <ModelPanel
          v-else
          :model="record"
          :details="detailsVisible"
          :count="record.count"
        />
      </template>
    </FilteredList>

    <AddonsModal ref="addonsModal" />
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import FilteredList from 'frontend/core/components/FilteredList'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import ModelPanel from 'frontend/components/Models/Panel'
import FleetVehiclesFilterForm from 'frontend/components/Fleets/FilterForm'
import FleetModelsFilterForm from 'frontend/components/Models/FilterForm'
import ModelClassLabels from 'frontend/components/Models/ClassLabels'
import AddonsModal from 'frontend/components/Vehicles/AddonsModal'
import Avatar from 'frontend/core/components/Avatar'
import MetaInfo from 'frontend/mixins/MetaInfo'
import HangarItemsMixin from 'frontend/mixins/HangarItems'
import { publicFleetRouteGuard } from 'frontend/utils/RouteGuards'
import fleetVehiclesCollection from 'frontend/api/collections/FleetVehicles'
import fleetsCollection from 'frontend/api/collections/Fleets'

@Component<FleetDetail>({
  beforeRouteEnter: publicFleetRouteGuard,
  components: {
    Btn,
    BtnDropdown,
    FilteredList,
    ModelPanel,
    ModelClassLabels,
    AddonsModal,
    FleetVehiclesFilterForm,
    FleetModelsFilterForm,
    Avatar,
  },
  mixins: [MetaInfo, HangarItemsMixin],
})
export default class FleetDetail extends Vue {
  vehiclesCollection: FleetVehiclesCollection = fleetVehiclesCollection

  @Getter('grouped', { namespace: 'fleet' }) grouped

  @Getter('money', { namespace: 'fleet' }) money

  @Getter('detailsVisible', { namespace: 'fleet' }) detailsVisible

  @Getter('mobile') mobile

  get fleet() {
    return fleetsCollection.record
  }

  get metaTitle() {
    if (!this.fleet) {
      return null
    }

    return this.fleet.name
  }

  get fleetStats() {
    return this.vehiclesCollection.stats
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
      slug: this.$route.params.slug,
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
    this.fetch()
  }

  @Watch('fleet')
  onFleetChange() {
    this.fetch()
  }

  mounted() {
    this.fetchFleet()
    this.fetch()
  }

  showAddonsModal(vehicle) {
    this.$refs.addonsModal.open(vehicle)
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

  fetch() {
    if (!this.fleet || !this.fleet.myFleet) {
      return
    }

    this.vehiclesCollection.findStats(this.filters)
  }

  async fetchFleet() {
    await fleetsCollection.findBySlug(this.$route.params.slug)
  }
}
</script>
