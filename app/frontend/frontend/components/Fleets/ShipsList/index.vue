<template>
  <div class="row">
    <div class="col-12 col-lg-12">
      <div class="fleet-header">
        <div class="fleet-labels">
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
        :hide-loading="fleetchartVisible"
      >
        <template slot="actions">
          <BtnDropdown size="small">
            <template v-if="mobile">
              <Btn
                size="small"
                variant="dropdown"
                data-test="fleetchart-link"
                @click.native="toggleFleetchart"
              >
                <i class="fad fa-starship" />
                <span>{{ $t('labels.fleetchart') }}</span>
              </Btn>

              <ShareBtn
                v-if="fleet.publicFleet"
                :url="shareUrl"
                :title="metaTitle"
                size="small"
                variant="dropdown"
              />

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

          <FleetchartApp
            :items="records"
            namespace="fleet"
            :loading="loading"
            :download-name="`${fleet.slug}-fleetchart`"
          />
        </template>
      </FilteredList>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import FilteredList from '@/frontend/core/components/FilteredList'
import FilteredGrid from '@/frontend/core/components/FilteredGrid'
import Btn from '@/frontend/core/components/Btn'
import BtnDropdown from '@/frontend/core/components/BtnDropdown'
import ShareBtn from '@/frontend/components/ShareBtn'
import FleetVehiclePanel from '@/frontend/components/Fleets/VehiclePanel'
import FleetVehiclesFilterForm from '@/frontend/components/Fleets/FilterForm'
import FleetchartApp from '@/frontend/components/Fleetchart/App'
import ModelClassLabels from '@/frontend/components/Models/ClassLabels'
import fleetVehiclesCollection from '@/frontend/api/collections/FleetVehicles'
import debounce from 'lodash.debounce'

export default {
  name: 'FleetShipsList',

  components: {
    Btn,
    BtnDropdown,
    FilteredList,
    FilteredGrid,
    FleetVehiclePanel,
    ModelClassLabels,
    FleetchartApp,
    FleetVehiclesFilterForm,
    ShareBtn,
  },

  props: {
    fleet: {
      type: Object,
      required: true,
    },

    shareUrl: {
      type: String,
      required: true,
    },

    metaTitle: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      collection: fleetVehiclesCollection,
      fleetVehiclesChannel: null,
    }
  },

  computed: {
    ...mapGetters(['mobile']),

    ...mapActions('fleet', [
      'grouped',
      'money',
      'detailsVisible',
      'perPage',
      'fleetchartVisible',
    ]),

    fleetStats() {
      return this.collection.stats
    },

    toggleDetailsTooltip() {
      if (this.detailsVisible) {
        return this.$t('actions.hideDetails')
      }
      return this.$t('actions.showDetails')
    },

    routeParams() {
      return {
        ...this.$route.params,
        grouped: this.grouped,
      }
    },

    filters() {
      return {
        slug: this.fleet.slug,
        filters: this.$route.query.q,
        grouped: this.grouped,
        page: this.$route.query.page,
      }
    },
  },

  watch: {
    perPage() {
      this.fetch()
    },
    grouped() {
      this.fetch()
    },

    $route() {
      this.fetchStats()
    },

    fleet() {
      this.fetchStats()
    },
  },

  mounted() {
    this.fetchStats()
    this.setupUpdates()
  },

  methods: {
    ...mapActions('fleet', [
      'toggleFleetchart',
      'toggleDetails',
      'toggleGrouped',
      'toggleMoney',
    ]),

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
        }
      )
    },

    async fetch() {
      await this.collection.findAll(this.filters)
      await this.fetchStats()
    },

    async fetchStats() {
      await this.collection.findStats(this.filters)
    },
  },
}
</script>
