<template>
  <section class="container hangar">
    <div class="row">
      <div class="col-xs-12 col-md-12">
        <div class="row">
          <div class="col-xs-12">
            <h1 class="sr-only">
              {{ $t('headlines.hangar.index') }}
            </h1>
          </div>
        </div>
        <div class="hangar-header">
          <div class="hangar-labels">
            <ModelClassLabels
              v-if="vehiclesCount"
              :label="$t('labels.hangar')"
              :count-data="vehiclesCount.classifications"
              filter-key="classificationIn"
            />
            <GroupLabels
              v-if="
                vehicles.length ||
                  fleetchartVehicles.length ||
                  (!vehicles.length &&
                    !fleetchartVehicles.length &&
                    isFilterSelected)
              "
              :hangar-groups="hangarGroups"
              :hangar-group-counts="hangarGroupCounts"
              :label="$t('labels.groups')"
            />
          </div>
          <div v-if="!mobile" class="page-actions">
            <Btn
              v-tooltip="$t('labels.poweredByStarship42')"
              :href="starship42Url"
            >
              {{ $t('labels.3dView') }}
            </Btn>
            <Btn
              v-tooltip="$t('labels.hangarStats')"
              :to="{ name: 'hangar-stats' }"
            >
              <i class="fal fa-chart-bar" />
            </Btn>
            <Btn :href="publicUrl">
              {{ $t('labels.publicUrl') }}
            </Btn>
          </div>
        </div>
        <div
          v-if="
            vehicles.length > 0 &&
              vehiclesCount &&
              vehiclesCount.metrics &&
              !mobile
          "
          class="row"
        >
          <div
            class="col-xs-12 hangar-metrics metrics-block"
            @click="toggleMoney"
          >
            <div v-if="money" class="metrics-item">
              <div class="metrics-label">
                {{ $t('labels.hangarMetrics.totalMoney') }}:
              </div>
              <div class="metrics-value">
                {{ $toDollar(vehiclesCount.metrics.totalMoney) }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ $t('labels.hangarMetrics.total') }}:
              </div>
              <div class="metrics-value">
                {{ $toNumber(vehiclesCount.total, 'ships') }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ $t('labels.hangarMetrics.totalMinCrew') }}:
              </div>
              <div class="metrics-value">
                {{ $toNumber(vehiclesCount.metrics.totalMinCrew, 'people') }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ $t('labels.hangarMetrics.totalMaxCrew') }}:
              </div>
              <div class="metrics-value">
                {{ $toNumber(vehiclesCount.metrics.totalMaxCrew, 'people') }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ $t('labels.hangarMetrics.totalCargo') }}:
              </div>
              <div class="metrics-value">
                {{ $toNumber(vehiclesCount.metrics.totalCargo, 'cargo') }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <FilteredList>
      <template slot="actions">
        <Btn
          v-tooltip="$t('actions.addVehicle')"
          :aria-label="$t('actions.addVehicle')"
          size="small"
          @click.native="showNewModal"
        >
          <i class="fas fa-plus" />
        </Btn>
        <BtnDropdown size="small">
          <template v-if="mobile">
            <Btn :href="starship42Url" size="small" variant="link">
              <i class="fad fa-cube" />
              {{ $t('labels.exportStarship42') }}
            </Btn>

            <Btn :to="{ name: 'hangar-stats' }" size="small" variant="link">
              <i class="fad fa-chart-bar" />
              {{ $t('labels.hangarStats') }}
            </Btn>

            <Btn :href="publicUrl" size="small" variant="link">
              <i class="fad fa-share-square" />
              {{ $t('labels.publicUrl') }}
            </Btn>

            <hr />
          </template>

          <Btn size="small" variant="link" @click.native="toggleFleetchart">
            <template v-if="fleetchartVisible">
              <i class="fas fa-th" />
              {{ $t('actions.hideFleetchart') }}
            </template>
            <template v-else>
              <i class="fad fa-starship" />
              {{ $t('actions.showFleetchart') }}
            </template>
          </Btn>

          <Btn
            v-show="!fleetchartVisible"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="link"
            @click.native="toggleDetails"
          >
            <i class="fad fa-info-square" />
            {{ toggleDetailsTooltip }}
          </Btn>

          <DownloadScreenshotBtn
            v-if="fleetchartVisible"
            element="#fleetchart"
            filename="my-hangar-fleetchart"
            size="small"
            variant="link"
            :show-tooltip="false"
          />

          <Btn
            :active="showGuide"
            :aria-label="toggleGuideTooltip"
            size="small"
            variant="link"
            @click.native="toggleGuide"
          >
            <i class="fad fa-question" />
            {{ toggleGuideTooltip }}
          </Btn>

          <hr />

          <Btn
            size="small"
            variant="link"
            :aria-label="$t('actions.export')"
            @click.native="exportJson"
          >
            <i class="fal fa-download" />
            {{ $t('actions.export') }}
          </Btn>

          <HangarImportBtn size="small" variant="link" @uploaded="fetch" />

          <hr />

          <Btn
            size="small"
            variant="link"
            :disabled="deleting"
            :aria-label="$t('actions.hangar.destroyAll')"
            @click.native="destroyAll"
          >
            <i class="fal fa-trash" />
            {{ $t('actions.hangar.destroyAll') }}
          </Btn>
        </BtnDropdown>
      </template>

      <Paginator
        v-if="!fleetchartVisible && vehicles.length"
        slot="pagination-top"
        :page="currentPage"
        :total="totalPages"
        :center="true"
      />

      <VehiclesFilterForm slot="filter" :hangar-groups-options="hangarGroups" />

      <template v-slot:default="{ filterVisible }">
        <transition name="fade" appear>
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

        <HangarGuideBox v-if="!loading && showGuide" />

        <FleetchartList
          v-else-if="fleetchartVisible"
          :items="fleetchartVehicles"
          :on-edit="showEditModal"
          :on-addons="showAddonsModal"
          :scale="fleetchartScale"
        />

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
              'col-lg-4': filterVisible,
              'col-xlg-4': !filterVisible,
            }"
            class="col-xs-12 col-sm-6 col-xxlg-2-4 fade-list-item"
          >
            <ModelPanel
              :model="vehicle.model"
              :vehicle="vehicle"
              :details="detailsVisible"
              :on-edit="showEditModal"
              :on-addons="showAddonsModal"
              is-my-ship
            />
          </div>
        </transition-group>

        <EmptyBox :visible="emptyBoxVisible" />

        <Loader :loading="loading" fixed />
      </template>

      <Paginator
        v-if="!fleetchartVisible && vehicles.length"
        slot="pagination-bottom"
        :page="currentPage"
        :total="totalPages"
        :center="true"
      />
    </FilteredList>

    <VehicleModal ref="vehicleModal" :hangar-groups="hangarGroups" />

    <AddonsModal ref="addonsModal" modifiable />

    <NewVehiclesModal ref="newVehiclesModal" />
  </section>
</template>

<script>
import qs from 'qs'
import { mapGetters } from 'vuex'
import Loader from 'frontend/components/Loader'
import FilteredList from 'frontend/components/FilteredList'
import Btn from 'frontend/components/Btn'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import BtnDropdown from 'frontend/components/BtnDropdown'
import ModelPanel from 'frontend/components/Models/Panel'
import HangarImportBtn from 'frontend/components/HangarImportBtn'
import FleetchartList from 'frontend/partials/Fleetchart/List'
import VehiclesFilterForm from 'frontend/partials/Vehicles/FilterForm'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'
import GroupLabels from 'frontend/partials/Vehicles/GroupLabels'
import EmptyBox from 'frontend/partials/EmptyBox'
import HangarGuideBox from 'frontend/partials/HangarGuideBox'
import VehicleModal from 'frontend/partials/Vehicles/Modal'
import AddonsModal from 'frontend/partials/Vehicles/AddonsModal'
import NewVehiclesModal from 'frontend/partials/Vehicles/NewVehiclesModal'
import FleetchartSlider from 'frontend/partials/Fleetchart/Slider'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Filters from 'frontend/mixins/Filters'
import Pagination from 'frontend/mixins/Pagination'
import Hash from 'frontend/mixins/Hash'
import { format } from 'date-fns'

export default {
  name: 'Hangar',

  components: {
    Loader,
    FilteredList,
    Btn,
    BtnDropdown,
    HangarImportBtn,
    DownloadScreenshotBtn,
    ModelPanel,
    FleetchartList,
    VehiclesFilterForm,
    ModelClassLabels,
    GroupLabels,
    EmptyBox,
    HangarGuideBox,
    VehicleModal,
    AddonsModal,
    NewVehiclesModal,
    FleetchartSlider,
  },

  mixins: [MetaInfo, Filters, Pagination, Hash],

  data() {
    return {
      loading: true,
      deleting: false,
      vehicles: [],
      fleetchartVehicles: [],
      hangarGroups: [],
      vehiclesCount: null,
      tooltipTrigger: 'click',
      showGuide: true,
      vehiclesChannel: null,
    }
  },

  computed: {
    ...mapGetters(['mobile']),

    ...mapGetters('session', ['currentUser']),

    ...mapGetters('hangar', [
      'ships',
      'detailsVisible',
      'fleetchartVisible',
      'fleetchartScale',
      'money',
    ]),

    emptyBoxVisible() {
      return (
        !this.loading &&
        (this.noVehicles || this.noFleetchartVehicles) &&
        this.isFilterSelected
      )
    },

    hangarGroupCounts() {
      if (!this.vehiclesCount) {
        return []
      }

      return this.vehiclesCount.groups
    },

    noVehicles() {
      return !this.vehicles.length && !this.fleetchartVisible
    },

    noFleetchartVehicles() {
      return !this.fleetchartVehicles.length && this.fleetchartVisible
    },

    toggleDetailsTooltip() {
      if (this.detailsVisible) {
        return this.$t('actions.hideDetails')
      }
      return this.$t('actions.showDetails')
    },

    toggleGuideTooltip() {
      if (this.showGuide) {
        return this.$t('actions.hideGuide')
      }
      return this.$t('actions.showGuide')
    },

    publicUrl() {
      if (!this.currentUser) {
        return ''
      }
      return `/hangar/${this.currentUser.username}`
    },

    starship42Url() {
      const shipList = this.fleetchartVehicles.map(
        vehicle => vehicle.model.rsiName,
      )
      const data = { type: 'matrix', s: shipList }
      const startship42Params = qs.stringify(data)
      return `http://www.starship42.com/fleetview/?${startship42Params}`
    },
  },

  watch: {
    $route() {
      this.fetch()
    },
  },

  mounted() {
    this.fetch()
    this.setupUpdates()
    this.$comlink.$on('vehicleSave', this.fetch)
    this.$comlink.$on('vehicleDelete', this.removeVehicle)
    this.$comlink.$on('hangarGroupDelete', this.fetch)
    this.$comlink.$on('hangarGroupSave', this.fetchGroups)

    if (this.$route.query.fleetchart && !this.fleetchartVisible) {
      this.$store.dispatch('hangar/toggleFleetchart')
    }
  },

  beforeDestroy() {
    if (this.vehiclesChannel) {
      this.vehiclesChannel.unsubscribe()
    }

    this.$comlink.$off('vehicleSave')
    this.$comlink.$off('vehicleDelete')
    this.$comlink.$off('hangarGroupDelete')
    this.$comlink.$off('hangarGroupSave')
  },

  methods: {
    toggleGuide() {
      this.showGuide = !this.showGuide
    },

    showEditModal(vehicle) {
      this.$refs.vehicleModal.open(vehicle)
    },

    updateScale(value) {
      this.$store.commit('hangar/setFleetchartScale', value)
    },

    showNewModal() {
      this.$refs.newVehiclesModal.open()
    },

    showAddonsModal(vehicle) {
      this.$refs.addonsModal.open(vehicle)
    },

    toggleDetails() {
      this.$store.dispatch('hangar/toggleDetails')
    },

    toggleFleetchart() {
      this.$store.dispatch('hangar/toggleFleetchart')
    },

    toggleMoney() {
      this.$store.dispatch('hangar/toggleMoney')
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
      this.resetLoading()

      if (this.vehicles.length) {
        this.showGuide = false
      }
    },

    removeVehicle(vehicle) {
      const index = this.vehicles.findIndex(item => item.id === vehicle.id)
      if (index >= 0) {
        this.vehicles.splice(index, 1)
      }
    },

    async fetchCount() {
      const response = await this.$api.get('vehicles/quick-stats', {
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
      this.resetLoading()
    },

    setupUpdates() {
      if (this.vehiclesChannel) {
        this.vehiclesChannel.unsubscribe()
      }

      this.vehiclesChannel = this.$cable.consumer.subscriptions.create(
        {
          channel: 'HangarChannel',
        },
        {
          received: this.fetch,
        },
      )
    },

    async fetchGroups() {
      const response = await this.$api.get('hangar-groups')
      if (!response.error) {
        this.hangarGroups = response.data
      }
    },

    resetLoading() {
      setTimeout(() => {
        this.loading = false
      }, 300)
    },

    async exportJson() {
      const response = await this.$api.download('vehicles/export')
      const link = document.createElement('a')
      link.href = window.URL.createObjectURL(new Blob([response.data]))
      link.setAttribute(
        'download',
        `fleetyards-${this.currentUser.username}-hangar-${format(
          new Date(),
          'yyyy-MM-dd',
        )}.json`,
      )
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    },

    async destroyAll() {
      this.deleting = true
      this.$confirm({
        text: this.$t('messages.confirm.hangar.destroyAll'),
        onConfirm: async () => {
          this.loading = true
          const response = await this.$api.destroy('vehicles/destroy-all')

          if (!response.error) {
            this.fetch()
          }

          this.deleting = false
          this.loading = false
        },
        onCancel: () => {
          this.deleting = false
        },
      })
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
