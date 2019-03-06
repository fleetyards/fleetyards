<template>
  <section class="container hangar">
    <div class="row">
      <div class="col-xs-12 col-md-12">
        <div class="row">
          <div class="col-xs-12">
            <h1 class="sr-only">
              {{ t('headlines.hangar') }}
            </h1>
          </div>
        </div>
        <div class="hangar-header">
          <div>
            <ModelClassLabels
              v-if="vehiclesCount"
              :label="t('labels.hangar')"
              :count-data="vehiclesCount"
              filter-key="classificationIn"
            />
            <GroupLabels
              v-if="!mobile && (vehicles.length || fleetchartVehicles.length
                || (!vehicles.length && !fleetchartVehicles.length && isFilterSelected))"
              :hangar-groups="hangarGroups"
              :label="t('labels.groups')"
            />
          </div>
          <div class="page-actions">
            <ExternalLink
              v-tooltip="t('labels.poweredByStarship42')"
              :url="starship42Url"
            >
              {{ t('labels.3dView') }}
            </ExternalLink>
            <ExternalLink :url="publicUrl">
              {{ t('labels.publicUrl') }}
            </ExternalLink>
          </div>
        </div>
        <div
          v-if="vehicles.length > 0 && vehiclesCount && vehiclesCount.metrics"
          class="row"
        >
          <div class="col-xs-12 hangar-metrics metrics-block">
            <div class="metrics-item">
              <div class="metrics-label">
                {{ t('labels.hangarMetrics.totalMoney') }}:
              </div>
              <div class="metrics-value">
                {{ toDollar(vehiclesCount.metrics.totalMoney) }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ t('labels.hangarMetrics.totalMinCrew') }}:
              </div>
              <div class="metrics-value">
                {{ toNumber(vehiclesCount.metrics.totalMinCrew, 'people') }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ t('labels.hangarMetrics.totalMaxCrew') }}:
              </div>
              <div class="metrics-value">
                {{ toNumber(vehiclesCount.metrics.totalMaxCrew, 'people') }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ t('labels.hangarMetrics.totalCargo') }}:
              </div>
              <div class="metrics-value">
                {{ toNumber(vehiclesCount.metrics.totalCargo, 'cargo') }}
              </div>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-6">
            <div class="page-actions page-actions-left">
              <Btn
                v-show="!hangarFleetchartVisible && vehicles.length"
                v-tooltip="toggleDetailsTooltip"
                :active="hangarDetailsVisible"
                :aria-label="toggleDetailsTooltip"
                small
                @click.native="toggleDetails"
              >
                <i
                  :class="{
                    'fa fa-chevron-up': hangarDetailsVisible,
                    'far fa-chevron-down': !hangarDetailsVisible,
                  }"
                />
              </Btn>
              <Btn
                v-tooltip="toggleFiltersTooltip"
                :active="hangarFilterVisible"
                :aria-label="toggleFiltersTooltip"
                small
                @click.native="toggleFilter"
              >
                <i
                  :class="{
                    fas: hangarFilterVisible,
                    far: !hangarFilterVisible,
                  }"
                  class="fa-filter"
                />
              </Btn>
              <DownloadScreenshotBtn
                v-if="hangarFleetchartVisible"
                element="#fleetchart"
                filename="my-hangar-fleetchart"
              />
              <Btn
                small
                @click.native="toggleFleetchart"
              >
                <template v-if="hangarFleetchartVisible">
                  {{ t('actions.hideFleetchart') }}
                </template>
                <template v-else>
                  {{ t('actions.showFleetchart') }}
                </template>
              </Btn>
            </div>
          </div>
          <div class="col-xs-12 col-md-6">
            <Paginator
              v-if="!hangarFleetchartVisible && vehicles.length"
              :page="currentPage"
              :total="totalPages"
              right
            />
          </div>
        </div>
        <div class="row">
          <transition
            name="slide"
            appear
            @before-enter="toggleFullscreen"
            @after-leave="toggleFullscreen"
          >
            <div
              v-show="hangarFilterVisible"
              class="col-md-3 col-xlg-2"
            >
              <VehiclesFilterForm :hangar-groups-options="hangarGroups" />
            </div>
          </transition>
          <div
            :class="{
              'col-md-9 col-xlg-10': !fullscreen,
            }"
            class="col-xs-12 col-animated"
          >
            <transition
              name="fade"
              appear
            >
              <div
                v-if="hangarFleetchartVisible && fleetchartVehicles.length"
                class="row"
              >
                <div class="col-xs-12 col-md-4 col-md-offset-4 fleetchart-slider">
                  <FleetchartSlider scale-key="HangarFleetchartScale" />
                </div>
              </div>
            </transition>
            <div
              v-if="hangarFleetchartVisible"
              class="row"
            >
              <div class="col-xs-12 fleetchart-wrapper">
                <transition-group
                  id="fleetchart"
                  name="fade-list"
                  class="flex-row fleetchart"
                  tag="div"
                  appear
                >
                  <FleetchartItem
                    v-for="vehicle in fleetchartVehicles"
                    :key="vehicle.id"
                    :model="vehicle.model"
                    :scale="HangarFleetchartScale"
                  />
                </transition-group>
              </div>
            </div>
            <transition-group
              v-else
              name="fade-list"
              class="flex-row"
              tag="div"
              appear
            >
              <div
                v-for="vehicle in vehicles"
                :key="vehicle.id"
                :class="{
                  'col-lg-4': fullscreen,
                  'col-xlg-4': !fullscreen,
                }"
                class="col-xs-12 col-sm-6 col-xxlg-2-4 fade-list-item"
              >
                <ModelPanel
                  :model="vehicle.model"
                  :vehicle="vehicle"
                  :details="hangarDetailsVisible"
                  :hangar-groups="hangarGroups"
                  :on-edit="showEditModal"
                  :on-addons="showAddonsModal"
                />
              </div>
            </transition-group>
            <EmptyBox v-if="emptyBoxVisible" />
            <HangarGuideBox v-if="guideVisible" />
            <Loader
              :loading="loading"
              fixed
            />
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12">
            <Paginator
              v-if="!hangarFleetchartVisible && vehicles.length"
              :page="currentPage"
              :total="totalPages"
              right
            />
          </div>
        </div>
      </div>
    </div>
    <VehicleModal
      ref="vehicleModal"
      :hangar-groups="hangarGroups"
    />
    <AddonsModal ref="addonsModal" />
  </section>
</template>

<script>
import qs from 'qs'
import { mapGetters } from 'vuex'
import Loader from 'frontend/components/Loader'
import Btn from 'frontend/components/Btn'
import ExternalLink from 'frontend/components/ExternalLink'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import ModelPanel from 'frontend/partials/Models/Panel'
import FleetchartItem from 'frontend/partials/Models/FleetchartItem'
import VehiclesFilterForm from 'frontend/partials/Vehicles/FilterForm'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'
import GroupLabels from 'frontend/partials/Vehicles/GroupLabels'
import EmptyBox from 'frontend/partials/EmptyBox'
import HangarGuideBox from 'frontend/partials/HangarGuideBox'
import VehicleModal from 'frontend/partials/Vehicles/Modal'
import AddonsModal from 'frontend/partials/Vehicles/AddonsModal'
import FleetchartSlider from 'frontend/partials/FleetchartSlider'
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Filters from 'frontend/mixins/Filters'
import Pagination from 'frontend/mixins/Pagination'
import Hash from 'frontend/mixins/Hash'

export default {
  components: {
    Loader,
    Btn,
    ExternalLink,
    DownloadScreenshotBtn,
    ModelPanel,
    FleetchartItem,
    VehiclesFilterForm,
    ModelClassLabels,
    GroupLabels,
    EmptyBox,
    HangarGuideBox,
    VehicleModal,
    AddonsModal,
    FleetchartSlider,
  },
  mixins: [I18n, MetaInfo, Filters, Pagination, Hash],
  data() {
    return {
      loading: true,
      vehicles: [],
      filters: [],
      fleetchartVehicles: [],
      hangarGroups: [],
      fullscreen: false,
      vehiclesCount: null,
      tooltipTrigger: 'click',
    }
  },
  computed: {
    ...mapGetters([
      'currentUser',
      'hangar',
      'hangarDetailsVisible',
      'hangarFleetchartVisible',
      'hangarFilterVisible',
      'HangarFleetchartScale',
      'mobile',
    ]),
    emptyBoxVisible() {
      return !this.loading && (this.noVehicles || this.noFleetchartVehicles) && this.filterPresent
    },
    guideVisible() {
      return !this.hangar.length
    },
    noVehicles() {
      return !this.vehicles.length && !this.hangarFleetchartVisible
    },
    noFleetchartVehicles() {
      return !this.fleetchartVehicles.length && this.hangarFleetchartVisible
    },
    filterPresent() {
      return this.isFilterSelected || this.$route.query.page
    },
    toggleDetailsTooltip() {
      if (this.hangarDetailsVisible) {
        return this.t('actions.hideDetails')
      }
      return this.t('actions.showDetails')
    },
    toggleFiltersTooltip() {
      if (this.hangarFilterVisible) {
        return this.t('actions.hideFilter')
      }
      return this.t('actions.showFilter')
    },
    publicUrl() {
      if (!this.currentUser) {
        return ''
      }
      return `/hangar/${this.currentUser.username}`
    },
    starship42Url() {
      const shipList = this.fleetchartVehicles.map(vehicle => vehicle.model.rsiName)
      const data = { source: 'FleetYards', type: 'matrix', s: shipList }
      const startship42Params = qs.stringify(data)
      return `http://www.starship42.com/fleetview/?${startship42Params}`
    },
  },
  watch: {
    $route() {
      this.fetch()
    },
    currentUser() {
      if (this.currentUser) {
        this.setupUpdates()
      }
    },
  },
  created() {
    this.fetch()
    this.$comlink.$on('vehicleSave', this.fetch)
    this.$comlink.$on('vehicleDelete', this.fetch)
    this.$comlink.$on('hangarGroupDelete', this.fetch)
    this.$comlink.$on('hangarGroupSave', this.fetchGroups)
    if (this.mobile) {
      this.$store.commit('setHangarFilterVisible', false)
    }
    this.toggleFullscreen()
  },
  methods: {
    showEditModal(vehicle) {
      this.$refs.vehicleModal.open(vehicle)
    },
    showAddonsModal(vehicle) {
      this.$refs.addonsModal.open(vehicle)
    },
    toggleFullscreen() {
      this.fullscreen = !this.hangarFilterVisible
    },
    toggleFilter() {
      this.$store.dispatch('toggleHangarFilter')
      this.updateSlider()
    },
    toggleDetails() {
      this.$store.dispatch('toggleHangarDetails')
    },
    toggleFleetchart() {
      this.$store.dispatch('toggleHangarFleetchart')
    },
    fetch() {
      this.fetchFleetchart()
      this.fetchVehicles()
      this.fetchGroups()
      this.fetchCount()
    },
    async fetchVehicles() {
      this.loading = true
      const response = await this.$api.get('vehicles', {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })
      if (!response.error) {
        this.vehicles = response.data
        this.scrollToAnchor()
      }
      this.setPages(response.meta)
      this.loading = false
    },
    async fetchCount() {
      const response = await this.$api.get('vehicles/count', {
        q: this.$route.query.q,
      })
      if (!response.error) {
        this.vehiclesCount = response.data
      }
    },
    async fetchFleetchart() {
      this.loading = true
      const response = await this.$api.get('vehicles/fleetchart', {
        q: this.$route.query.q,
      })
      if (!response.error) {
        this.fleetchartVehicles = response.data
      }
      this.loading = false
    },
    setupUpdates() {
      this.vehiclesChannel = this.$cable.subscriptions.create({
        channel: 'HangarChannel',
        username: this.currentUser.username,
      }, {
        received: this.fetch,
      })
    },
    async fetchGroups() {
      const response = await this.$api.get('hangar-groups')
      if (!response.error) {
        this.hangarGroups = response.data
      }
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.hangar'),
    })
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
