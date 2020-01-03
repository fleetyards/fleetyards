<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-8">
        <h1 v-if="fleet">
          <Avatar
            v-if="fleet.logo"
            :avatar="fleet.logo"
            :transparent="!!fleet.logo"
            icon="fad fa-image"
          />
          {{ fleet.name }}
        </h1>
      </div>
      <div class="col-xs-4">
        <div class="page-main-actions">
          <span v-tooltip="leaveTooltip">
            <Btn
              v-if="fleet"
              :disabled="fleet.role === 'admin' || leaving"
              inline
              variant="danger"
              @click.native="leave"
            >
              <i class="fal fa-sign-out" />
              {{ $t('actions.fleet.leave', { fleet: fleet.name }) }}
            </Btn>
          </span>
        </div>
      </div>
    </div>
    <div
      v-if="fleetCount"
      class="row"
    >
      <div class="col-xs-12">
        <ModelClassLabels
          v-if="isMember"
          :label="$t('labels.fleet.classes')"
          :count-data="fleetCount"
          filter-key="classificationIn"
        />
      </div>
    </div>
    <div
      v-if="fleetCount && fleetCount.metrics && !mobile && isMember"
      class="row"
    >
      <div
        class="col-xs-12 fleet-metrics metrics-block"
        @click="toggleMoney"
      >
        <div
          v-if="money"
          class="metrics-item"
        >
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
            {{ $toNumber(fleetCount.total, 'ships') }}
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
      :hide-filter="!isMember"
    >
      <template
        v-if="isMember"
        slot="actions"
      >
        <Btn
          v-show="!fleetchartVisible"
          v-tooltip="toggleDetailsTooltip"
          :active="detailsVisible"
          :aria-label="toggleDetailsTooltip"
          size="small"
          @click.native="toggleDetails"
        >
          <span v-show="detailsVisible">
            <i class="fa fa-chevron-up" />
          </span>
          <span v-show="!detailsVisible">
            <i class="far fa-chevron-down" />
          </span>
        </Btn>

        <DownloadScreenshotBtn
          v-if="fleet && fleetchartVisible"
          element="#fleetchart"
          :filename="`${fleet.slug}-fleetchart`"
        />

        <Btn
          size="small"
          @click.native="toggleFleetchart"
        >
          <template v-if="fleetchartVisible">
            {{ $t('actions.hideFleetchart') }}
          </template>
          <template v-else>
            {{ $t('actions.showFleetchart') }}
          </template>
        </Btn>

        <Btn
          v-if="!fleetchartVisible"
          size="small"
          @click.native="toggleGrouped"
        >
          <template v-if="grouped">
            {{ $t('actions.groupedByModel') }}
          </template>
          <template v-else>
            {{ $t('actions.ungrouped') }}
          </template>
        </Btn>
      </template>

      <Paginator
        v-if="!fleetchartVisible && (vehicles.length || models.length)"
        slot="pagination-top"
        :page="currentPage"
        :total="totalPages"
        right
      />

      <template slot="filter">
        <FleetModelsFilterForm v-if="grouped" />
        <FleetVehiclesFilterForm v-else />
      </template>

      <template v-slot:default="{ filterVisible }">
        <transition
          name="fade"
          appear
        >
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

        <div
          v-if="fleetchartVisible"
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
                :scale="fleetchartScale"
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
          <template v-if="grouped">
            <div
              v-for="model in models"
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
                :on-addons="showAddonsModal"
              />
            </div>
          </template>
        </transition-group>

        <EmptyBox :visible="emptyBoxVisible" />

        <Loader
          :loading="loading"
          fixed
        />
      </template>

      <Paginator
        v-if="!fleetchartVisible && (vehicles.length || models.length)"
        slot="pagination-bottom"
        :page="currentPage"
        :total="totalPages"
        right
      />
    </FilteredList>

    <AddonsModal ref="addonsModal" />
  </section>
</template>

<script>
import { mapGetters } from 'vuex'

import Loader from 'frontend/components/Loader'
import FilteredList from 'frontend/components/FilteredList'
import Btn from 'frontend/components/Btn'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import ModelPanel from 'frontend/components/Models/Panel'
import FleetchartItem from 'frontend/partials/Models/FleetchartItem'
import FleetVehiclesFilterForm from 'frontend/partials/Fleets/FilterForm'
import FleetModelsFilterForm from 'frontend/partials/Models/FilterForm'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'
import EmptyBox from 'frontend/partials/EmptyBox'
import AddonsModal from 'frontend/partials/Vehicles/AddonsModal'
import FleetchartSlider from 'frontend/partials/FleetchartSlider'
import Avatar from 'frontend/components/Avatar'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Filters from 'frontend/mixins/Filters'
import Pagination from 'frontend/mixins/Pagination'

export default {
  name: 'Fleet',

  components: {
    Btn,
    FilteredList,
    Loader,
    DownloadScreenshotBtn,
    ModelPanel,
    FleetchartItem,
    ModelClassLabels,
    EmptyBox,
    AddonsModal,
    FleetVehiclesFilterForm,
    FleetModelsFilterForm,
    FleetchartSlider,
    Avatar,
  },

  mixins: [
    MetaInfo,
    Pagination,
    Filters,
  ],

  data() {
    return {
      loading: false,
      leaving: false,
      fleet: null,
      fleetCount: null,
      vehicles: [],
      models: [],
      fleetchartVehicles: [],
      fleetchartModels: [],
    }
  },

  computed: {
    metaTitle() {
      if (!this.fleet) {
        return null
      }

      return this.fleet.name
    },

    ...mapGetters([
      'mobile',
    ]),

    ...mapGetters('fleet', [
      'detailsVisible',
      'fleetchartVisible',
      'fleetchartScale',
      'grouped',
      'money',
    ]),

    leaveTooltip() {
      if (this.fleet && this.fleet.role === 'admin') {
        return this.$t('texts.fleets.leaveInfo')
      }

      return null
    },

    emptyBoxVisible() {
      return !this.loading && (this.noVehicles || this.noFleetchartVehicles)
        && this.isFilterSelected
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

    isMember() {
      return this.fleet && this.fleet.acceptedAt
    },
  },

  watch: {
    $route() {
      this.fetch()
    },

    grouped() {
      if (this.isFilterSelected) {
        this.resetFilter()
      } else if (this.grouped) {
        this.fetchModels()
      } else {
        this.fetchVehicles()
      }
    },

    fleet() {
      if (this.fleet.backgroundImage) {
        this.$store.commit('setBackgroundImage', this.fleet.backgroundImage)
      }
    },
  },

  mounted() {
    this.fetch()

    if (this.$route.query.fleetchart && !this.fleetchartVisible) {
      this.$store.dispatch('fleet/toggleFleetchart')
    }
  },

  methods: {
    showAddonsModal(vehicle) {
      this.$refs.addonsModal.open(vehicle)
    },

    toggleDetails() {
      this.$store.dispatch('fleet/toggleDetails')
    },

    toggleFleetchart() {
      this.$store.dispatch('fleet/toggleFleetchart')
    },

    toggleGrouped() {
      this.$store.dispatch('fleet/toggleGrouped')
    },

    toggleMoney() {
      this.$store.dispatch('fleet/toggleMoney')
    },

    updateScale(value) {
      this.$store.commit('fleet/setFleetchartScale', value)
    },

    fetch() {
      this.fetchFleet()
    },

    fetchAdditional() {
      if (!this.isMember) {
        return
      }

      if (this.fleetchartVisible) {
        this.fetchFleetchart()
      } else if (this.grouped) {
        this.fetchModels()
      } else {
        this.fetchVehicles()
      }
      this.fetchFleetCount()
    },

    async fetchFleet() {
      this.loading = true

      const response = await this.$api.get(`fleets/${this.$route.params.slug}`)

      if (!response.error) {
        this.fleet = response.data
      } else if (response.error.response && response.error.response.status === 404) {
        this.$router.replace({ name: '404' })
      }

      this.fetchAdditional()

      this.resetLoading()
    },

    async fetchVehicles() {
      this.loading = true

      const response = await this.$api.get(`fleets/${this.$route.params.slug}/vehicles`, {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })

      if (!response.error) {
        this.vehicles = response.data
      }

      this.setPages(response.meta)

      this.resetLoading()
    },

    async fetchModels() {
      this.loading = true

      const response = await this.$api.get(`fleets/${this.$route.params.slug}/models`, {
        q: this.$route.query.q,
        page: this.$route.query.page,
      })

      if (!response.error) {
        this.models = response.data
      }

      this.setPages(response.meta)

      this.resetLoading()
    },

    async fetchFleetchart() {
      this.loading = true

      const response = await this.$api.get(`fleets/${this.$route.params.slug}/fleetchart`, {
        q: this.$route.query.q,
      })

      if (!response.error) {
        this.fleetchartVehicles = response.data
      }

      this.resetLoading()
    },

    async fetchFleetCount() {
      const response = await this.$api.get(`fleets/${this.$route.params.slug}/quick-stats`, {
        q: this.$route.query.q,
      })

      if (!response.error) {
        this.fleetCount = response.data
      }
    },

    async leave() {
      this.leaving = true
      this.$confirm({
        text: this.$t('messages.confirm.fleet.leave'),
        onConfirm: async () => {
          const response = await this.$api.destroy(`fleets/${this.fleet.slug}/members/leave`)

          if (!response.error) {
            this.$comlink.$emit('fleetUpdate')

            this.$success({
              text: this.$t('messages.fleet.leave.success'),
            })

            this.$router.push({ name: 'home' })
          } else {
            this.$alert({
              text: this.$t('messages.fleet.leave.failure'),
            })
            this.leaving = false
          }
        },
        onClose: () => {
          this.leaving = false
        },
      })
    },

    resetLoading() {
      setTimeout(() => {
        this.loading = false
      }, 300)
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
