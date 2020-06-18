<template>
  <section class="container">
    <div v-if="fleet" class="row">
      <div class="col-xs-12 col-md-8">
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
      <div class="col-xs-12 col-md-4 fleet-links">
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
    <div v-if="fleetCount" class="row">
      <div class="col-xs-12 col-md-8">
        <ModelClassLabels
          v-if="fleet && fleet.myFleet"
          :label="$t('labels.fleet.classes')"
          :count-data="fleetCount.classifications"
          filter-key="classificationIn"
        />
      </div>
      <div class="col-xs-12 col-md-4">
        <div class="page-actions">
          <!-- <Starship42Btn :vehicles="fleetchartVehicles" /> -->

          <Btn
            v-tooltip="$t('labels.hangarStats')"
            :to="{ name: 'fleet-stats' }"
          >
            <i class="fal fa-chart-bar" />
          </Btn>
        </div>
      </div>
    </div>

    <div
      v-if="
        fleetCount && fleetCount.metrics && !mobile && fleet && fleet.myFleet
      "
      class="row"
    >
      <div class="col-xs-12 fleet-metrics metrics-block" @click="toggleMoney">
        <div v-if="money" class="metrics-item">
          <div class="metrics-label">
            {{ $t('labels.hangarMetrics.totalMoney') }}:
          </div>
          <div class="metrics-value">
            {{ $toDollar(fleetCount.metrics.totalMoney) }}
          </div>
        </div>
        <div class="metrics-item">
          <div class="metrics-label">
            {{ $t('labels.hangarMetrics.total') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(fleetCount.totalShips, 'ships') }}
          </div>
        </div>
        <div class="metrics-item">
          <div class="metrics-label">
            {{ $t('labels.hangarMetrics.totalMinCrew') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(fleetCount.metrics.totalMinCrew, 'people') }}
          </div>
        </div>
        <div class="metrics-item">
          <div class="metrics-label">
            {{ $t('labels.hangarMetrics.totalMaxCrew') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(fleetCount.metrics.totalMaxCrew, 'people') }}
          </div>
        </div>
        <div class="metrics-item">
          <div class="metrics-label">
            {{ $t('labels.hangarMetrics.totalCargo') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(fleetCount.metrics.totalCargo, 'cargo') }}
          </div>
        </div>
      </div>
    </div>
    <FilteredList
      v-if="fleet && fleet.myFleet"
      :collection="grouped ? modelsCollection : vehiclesCollection"
      :name="$route.name"
      :route-query="$route.query"
      :params="$route.params"
      :hash="$route.hash"
      :paginated="true"
    >
      <template slot="actions">
        <BtnDropdown size="small">
          <template v-if="mobile">
            <!-- <Starship42Btn
              :vehicles="fleetchartVehicles"
              size="small"
              variant="link"
              :with-icon="true"
            /> -->

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
          <!--
          <DownloadScreenshotBtn
            v-if="fleet && fleetchartVisible"
            element="#fleetchart"
            :filename="`${fleet.slug}-fleetchart`"
            size="small"
            variant="link"
            :show-tooltip="false"
          /> -->

          <!-- <Btn size="small" variant="link" @click.native="toggleFleetchart">
            <template v-if="fleetchartVisible">
              <i class="fas fa-th" />
              {{ $t('actions.hideFleetchart') }}
            </template>
            <template v-else>
              <i class="fad fa-starship" />
              {{ $t('actions.showFleetchart') }}
            </template>
          </Btn> -->

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

      <template slot="filter">
        <FleetModelsFilterForm v-if="grouped" />
        <FleetVehiclesFilterForm v-else />
      </template>

      <template v-slot:default="{ records, filterVisible }">
        <!-- <transition name="fade" appear>
          <div
            v-if="fleetchartVisible && fleetchartVehicles.length"
            class="row"
          >
            <div class="col-xs-12 col-md-4 col-md-offset-4 fleetchart-slider">
              <FleetchartSlider
                :initial-scale="fleetchartScale"
                @change="updateScale"
              />
            </div>
          </div>
        </transition>

        <FleetchartList
          v-if="fleetchartVisible"
          :items="fleetchartVehicles"
          :scale="fleetchartScale"
        /> -->

        <transition-group name="fade-list" class="flex-row" tag="div" appear>
          <template v-if="grouped">
            <div
              v-for="model in records"
              :key="model.id"
              :class="{
                'col-lg-4': filterVisible,
                'col-xlg-4': !filterVisible,
              }"
              class="col-xs-12 col-sm-6 col-xxlg-2-4 fade-list-item"
            >
              <ModelPanel
                :model="model"
                :details="detailsVisible"
                :count="model.count"
              />
            </div>
          </template>
          <template v-else>
            <div
              v-for="vehicle in records"
              :key="vehicle.id"
              :class="{
                'col-lg-4': filterVisible,
                'col-xlg-4': !filterVisible,
              }"
              class="col-xs-12 col-sm-6 col-xxlg-2-4 fade-list-item"
            >
              <ModelPanel
                :model="vehicle.model"
                :details="detailsVisible"
                :on-addons="showAddonsModal"
              />
            </div>
          </template>
        </transition-group>
      </template>
    </FilteredList>

    <AddonsModal ref="addonsModal" />
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import FilteredList from 'frontend/components/FilteredList'
import Btn from 'frontend/components/Btn'
import BtnDropdown from 'frontend/components/BtnDropdown'
import Starship42Btn from 'frontend/components/Starship42Btn'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import ModelPanel from 'frontend/components/Models/Panel'
import FleetchartList from 'frontend/partials/Fleetchart/List'
import FleetVehiclesFilterForm from 'frontend/partials/Fleets/FilterForm'
import FleetModelsFilterForm from 'frontend/partials/Models/FilterForm'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'
import AddonsModal from 'frontend/partials/Vehicles/AddonsModal'
import FleetchartSlider from 'frontend/partials/Fleetchart/Slider'
import Avatar from 'frontend/components/Avatar'
import MetaInfo from 'frontend/mixins/MetaInfo'
import HangarItemsMixin from 'frontend/mixins/HangarItems'
import { publicFleetRouteGuard } from 'frontend/utils/Fleet'
import fleetModelsCollection from 'frontend/collections/FleetModels'
import fleetVehiclesCollection from 'frontend/collections/FleetVehicles'

@Component<FleetDetail>({
  components: {
    Btn,
    BtnDropdown,
    Starship42Btn,
    FilteredList,
    DownloadScreenshotBtn,
    ModelPanel,
    FleetchartList,
    ModelClassLabels,
    AddonsModal,
    FleetVehiclesFilterForm,
    FleetModelsFilterForm,
    FleetchartSlider,
    Avatar,
  },
  mixins: [MetaInfo, HangarItemsMixin],
  beforeRouteEnter: publicFleetRouteGuard,
})
export default class FleetDetail extends Vue {
  fleetCount: FleetStats | null = null

  fleet: Fleet | null = null

  modelsCollection: FleetModelsCollection = fleetModelsCollection

  vehiclesCollection: FleetVehiclesCollection = fleetVehiclesCollection

  @Getter('grouped', { namespace: 'fleet' }) grouped

  @Getter('money', { namespace: 'fleet' }) money

  @Getter('detailsVisible', { namespace: 'fleet' }) detailsVisible

  @Getter('mobile') mobile

  get metaTitle() {
    if (!this.fleet) {
      return null
    }

    return this.fleet.name
  }

  // ...mapGetters(['mobile']),

  // ...mapGetters('session', ['currentUser']),

  // ...mapGetters('fleet', [
  //   'detailsVisible',
  //   'fleetchartVisible',
  //   'fleetchartScale',
  //   'grouped',
  //   'money',
  // ]),

  get toggleDetailsTooltip() {
    if (this.detailsVisible) {
      return this.$t('actions.hideDetails')
    }
    return this.$t('actions.showDetails')
  }

  get filters() {
    return {
      slug: this.$route.params.slug,
      filters: this.$route.query.q,
      page: this.$route.query.page,
    }
  }

  @Watch('grouped')
  onGroupedChange() {
    if (this.grouped) {
      this.modelsCollection.findAll(this.filters)
    } else {
      this.vehiclesCollection.findAll(this.filters)
    }
  }

  mounted() {
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

  // updateScale(value) {
  //   this.$store.commit('fleet/setFleetchartScale', value)
  // }

  fetch() {
    // await this.statsCollection.findAll(this.filters)
  }

  // async fetchFleetchart() {
  //   this.loading = true

  //   const response = await this.$api.get(
  //     `fleets/${this.$route.params.slug}/fleetchart`,
  //     {
  //       q: this.$route.query.q,
  //     },
  //   )

  //   if (!response.error) {
  //     this.fleetchartVehicles = response.data
  //   }

  //   this.resetLoading()
  // }

  async fetchFleetCount() {
    const response = await this.$api.get(
      `fleets/${this.$route.params.slug}/quick-stats`,
      {
        q: this.$route.query.q,
      },
    )

    if (!response.error) {
      this.fleetCount = response.data
    }
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
