<template>
  <section class="container hangar">
    <div class="row">
      <div class="col-xs-12 col-md-12">
        <div class="row">
          <div class="col-xs-12 col-md-8">
            <h1 class="sr-only">{{ t('headlines.hangar') }}</h1>
          </div>
          <div class="col-xs-12 col-md-4 text-right">
            <button
              :aria-label="toggleFiltersTooltip"
              class="btn btn-link btn-filter hidden-md hidden-lg"
              @click="openFilter"
            >
              <i
                v-if="isFilterSelected"
                class="fas fa-filter"
              />
              <i
                v-else
                class="fal fa-filter"
              />
            </button>
          </div>
        </div>
        <div class="row">
          <div class="hidden-xs hidden-sm col-md-9 col-xlg-10">
            <ModelClassLabels
              v-if="vehiclesCount"
              :label="t('labels.hangar')"
              :count-data="vehiclesCount"
              filter-key="modelClassificationIn"
            />
            <GroupLabels
              v-if="vehicles.length || (!vehicles.length && isFilterSelected)"
              :hangar-groups="hangarGroups"
              :label="t('labels.groups')"
            />
          </div>
          <div class="col-sm-12 col-md-3 col-xlg-2">
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
        </div>
        <div
          v-if="vehicles.length > 0 && vehiclesCount && vehiclesCount.metrics"
          class="row"
        >
          <div class="col-xs-12 hangar-metrics metrics-block">
            <div class="row">
              <div class="col-xs-6 col-md-3">
                <div class="metrics-label">{{ t('labels.hangarMetrics.totalMoney') }}:</div>
                <div class="metrics-value">{{ toDollar(vehiclesCount.metrics.totalMoney) }}</div>
              </div>
              <div class="col-xs-6 col-md-3">
                <div class="metrics-label">{{ t('labels.hangarMetrics.totalMinCrew') }}:</div>
                <div class="metrics-value">
                  {{ toNumber(vehiclesCount.metrics.totalMinCrew, 'people') }}
                </div>
              </div>
              <div class="col-xs-6 col-md-3">
                <div class="metrics-label">{{ t('labels.hangarMetrics.totalMaxCrew') }}:</div>
                <div class="metrics-value">
                  {{ toNumber(vehiclesCount.metrics.totalMaxCrew, 'people') }}
                </div>
              </div>
              <div class="col-xs-6 col-md-3">
                <div class="metrics-label">{{ t('labels.hangarMetrics.totalCargo') }}:</div>
                <div class="metrics-value">
                  {{ toNumber(vehiclesCount.metrics.totalCargo, 'cargo') }}
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-6">
            <Paginator
              v-if="!hangarFleetchart && vehicles.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
          <div class="col-xs-12 col-md-6">
            <div class="page-actions">
              <Btn
                v-tooltip="t('actions.saveScreenshot')"
                v-show="hangarFleetchart && fleetchartVehicles.length > 0"
                :disabled="downloading"
                :aria-label="t('actions.saveScreenshot')"
                small
                @click.native="download"
              >
                <i class="fal fa-download" />
              </Btn>
              <Btn
                v-tooltip="toggleDetailsTooltip"
                v-show="!hangarFleetchart && vehicles.length > 0"
                :active="hangarDetails"
                :aria-label="toggleDetailsTooltip"
                small
                @click.native="toggleDetails"
              >
                <i class="fas fa-list" />
              </Btn>
              <Btn
                v-tooltip="toggleFiltersTooltip"
                :active="hangarFilterVisible"
                :aria-label="toggleFiltersTooltip"
                class="hidden-xs hidden-sm"
                small
                @click.native="toggleFilter"
              >
                <i
                  v-if="isFilterSelected"
                  class="fas fa-filter"
                />
                <i
                  v-else
                  class="fal fa-filter"
                />
              </Btn>
              <Btn
                small
                @click.native="toggleFleetchart"
              >
                <template v-if="hangarFleetchart">{{ t('actions.hideFleetchart') }}</template>
                <template v-else>{{ t('actions.showFleetchart') }}</template>
              </Btn>
            </div>
          </div>
        </div>
        <div class="row">
          <div
            :class="{
              'col-md-9 col-xlg-10': hangarFilterVisible,
            }"
            class="col-xs-12"
          >
            <div
              v-if="hangarFleetchart && fleetchartVehicles.length"
              class="row"
            >
              <div class="col-xs-12 col-md-4 col-md-offset-4 fleetchart-slider">
                <vue-slider
                  ref="scaleSlider"
                  v-model="scale"
                  :min="0.5"
                  :max="4"
                  :interval="0.1"
                  formatter="{value}x"
                  tooltip="hover"
                />
              </div>
            </div>
            <div
              v-if="hangarFleetchart"
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
                    :scale="scale"
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
                :class="{
                  'col-lg-4 col-xlg-3 col-xxlg-2': !hangarFilterVisible,
                  'col-xlg-4 col-xxlg-3': hangarFilterVisible,
                }"
                :key="vehicle.id"
                class="col-xs-12 col-sm-6 fade-list-item"
              >
                <ModelPanel
                  :model="vehicle.model"
                  :vehicle="vehicle"
                  :details="hangarDetails"
                  :hangar-groups="hangarGroups"
                />
              </div>
            </transition-group>
            <EmptyBox v-if="emptyBoxVisible" />
            <HangarGuideBox v-if="guideVisible" />
            <Loader
              v-if="loading"
              fixed
            />
          </div>
          <transition
            name="fade"
            appear
          >
            <div
              v-show="hangarFilterVisible"
              class="hidden-xs hidden-sm col-md-3 col-xlg-2"
            >
              <VehiclesFilterForm
                :filters="filters"
                :hangar-groups-options="hangarGroups"
              />
            </div>
          </transition>
        </div>
        <div class="row">
          <div class="col-xs-12">
            <Paginator
              v-if="!hangarFleetchart && vehicles.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
        <VehiclesFilterModal
          ref="filterModal"
          :filters="filters"
          :vehicles-count="vehiclesCount"
          :hangar-groups-options="hangarGroups"
        />
      </div>
    </div>
  </section>
</template>

<script>
import qs from 'qs'
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Pagination from 'frontend/mixins/Pagination'
import Hash from 'frontend/mixins/Hash'
import Loader from 'frontend/components/Loader'
import Btn from 'frontend/components/Btn'
import ExternalLink from 'frontend/components/ExternalLink'
import ModelPanel from 'frontend/partials/Models/Panel'
import FleetchartItem from 'frontend/partials/Models/FleetchartItem'
import VehiclesFilterForm from 'frontend/partials/Vehicles/FilterForm'
import VehiclesFilterModal from 'frontend/partials/Vehicles/FilterModal'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'
import GroupLabels from 'frontend/partials/Vehicles/GroupLabels'
import Filters from 'frontend/mixins/Filters'
import { mapGetters } from 'vuex'
import EmptyBox from 'frontend/partials/EmptyBox'
import HangarGuideBox from 'frontend/partials/HangarGuideBox'
import vueSlider from 'vue-slider-component'
import html2canvas from 'html2canvas'
import download from 'downloadjs'

export default {
  components: {
    FleetchartItem,
    EmptyBox,
    HangarGuideBox,
    ModelPanel,
    Loader,
    Btn,
    ExternalLink,
    VehiclesFilterForm,
    VehiclesFilterModal,
    ModelClassLabels,
    GroupLabels,
    vueSlider,
  },
  mixins: [I18n, MetaInfo, Filters, Pagination, Hash],
  data() {
    return {
      loading: false,
      downloading: false,
      vehicles: [],
      filters: [],
      fleetchartVehicles: [],
      hangarGroups: [],
      vehiclesCount: null,
      tooltipTrigger: 'click',
      scale: this.$store.state.hangarFleetchartScale,
    }
  },
  computed: {
    ...mapGetters([
      'currentUser',
      'hangar',
      'hangarDetails',
      'hangarFleetchart',
      'hangarFilterVisible',
    ]),
    emptyBoxVisible() {
      return !this.loading && !this.vehicles.length && (this.isFilterSelected
        || this.$route.query.page)
    },
    guideVisible() {
      return !this.loading && !this.vehicles.length && !this.isFilterSelected
        && !this.fleetchartVehicles.length
    },
    toggleDetailsTooltip() {
      if (this.hangarDetails) {
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
      const shipList = this.vehicles.map(vehicle => vehicle.model.rsiName)
      const data = { source: 'FleetYards', type: 'matrix', s: shipList }
      const startship42Params = qs.stringify(data)
      return `http://www.starship42.com/fleetview/?${startship42Params}`
    },
  },
  watch: {
    $route() {
      this.fetch()
    },
    scale(value) {
      this.$store.commit('setHangarFleetchartScale', value)
    },
    currentUser() {
      if (this.currentUser) {
        this.setupUpdates()
      }
    },
    hangarFleetchart() {
      this.fetch()
    },
  },
  created() {
    this.fetch()
    this.fetchFilters()
    this.$comlink.$on('vehicleSave', this.fetch)
    this.$comlink.$on('vehicleDelete', this.fetch)
    this.$comlink.$on('hangarGroupDelete', this.fetch)
    this.$comlink.$on('hangarGroupSave', this.fetchGroups)
  },
  methods: {
    download() {
      this.downloading = true
      html2canvas(document.querySelector('#fleetchart'), {
        backgroundColor: null,
        useCORS: true,
      }).then((canvas) => {
        this.downloading = false
        download(canvas.toDataURL(), 'fleetchart.png')
      })
    },
    toggleFilter() {
      this.$store.commit('toggleHangarFilter')
    },
    toggleDetails() {
      this.$store.commit('toggleHangarDetails')
    },
    toggleFleetchart() {
      this.$store.commit('toggleHangarFleetchart')
    },
    openFilter() {
      this.$refs.filterModal.open()
    },
    fetch() {
      if (this.hangarFleetchart) {
        this.fetchFleetchart()
      } else {
        this.fetchVehicles()
      }
      this.fetchGroups()
      this.fetchCount()
    },
    async fetchVehicles() {
      this.loading = true
      const response = await this.$api.get('vehicles', {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })
      this.loading = false
      if (!response.error) {
        this.vehicles = response.data
        this.scrollToAnchor()
      }
      this.setPages(response.meta)
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
      this.loading = false
      this.$nextTick(() => {
        if (this.$refs.scaleSlider) {
          setTimeout(this.$refs.scaleSlider.refresh, 500)
        }
      })
      if (!response.error) {
        this.fleetchartVehicles = response.data
      }
    },
    setupUpdates() {
      this.vehiclesChannel = this.$cable.subscriptions.create({
        channel: 'HangarChannel',
        username: this.currentUser.username,
      }, {
        received: this.update,
      })
    },
    update(data) {
      const vehicle = JSON.parse(data)
      if (!vehicle.deleted) {
        this.fetch()
      }
    },
    async fetchGroups() {
      const response = await this.$api.get('hangar-groups', {})
      if (!response.error) {
        this.hangarGroups = response.data
      }
    },
    async fetchFilters() {
      const response = await this.$api.get('models/filters', {})
      if (!response.error) {
        this.filters = response.data
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
