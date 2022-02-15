<template>
  <section class="container hangar">
    <div class="row">
      <div class="col-12 col-lg-12">
        <div class="row">
          <div class="col-12">
            <h1 class="sr-only">
              {{ $t('headlines.hangar.index') }}
            </h1>
          </div>
        </div>
        <div class="hangar-header">
          <div class="hangar-labels">
            <ModelClassLabels
              v-if="hangarStats"
              :count-data="hangarStats.classifications"
              :label="$t('labels.hangar')"
              filter-key="classificationIn"
            />
            <GroupLabels
              v-if="hangarStats"
              :hangar-groups="groupsCollection.records"
              :hangar-group-counts="hangarGroupCounts"
              :label="$t('labels.groups')"
              :editable="true"
              @highlight="highlightGroup"
            />
          </div>
          <div v-if="!mobile" class="page-actions page-actions-right">
            <Btn data-test="fleetchart-link" @click.native="toggleFleetchart">
              <i class="fad fa-starship" />
              {{ $t('labels.fleetchart') }}
            </Btn>

            <Btn :to="{ name: 'hangar-stats' }">
              <i class="fal fa-chart-bar" />
              {{ $t('labels.hangarStats') }}
            </Btn>

            <ShareBtn
              v-if="currentUser && currentUser.publicHangar"
              :url="shareUrl"
              :title="metaTitle"
            />
          </div>
        </div>
        <div
          v-if="
            collection.records.length &&
            hangarStats &&
            hangarStats.metrics &&
            !mobile
          "
          class="row"
        >
          <div class="col-12 hangar-metrics metrics-block" @click="toggleMoney">
            <div v-if="money" class="metrics-item">
              <div class="metrics-label">
                {{ $t('labels.hangarMetrics.totalMoney') }}:
              </div>
              <div class="metrics-value">
                {{ $toDollar(hangarStats.metrics.totalMoney) }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ $t('labels.hangarMetrics.total') }}:
              </div>
              <div class="metrics-value">
                {{ $toNumber(hangarStats.total, 'ships') }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ $t('labels.hangarMetrics.totalMinCrew') }}:
              </div>
              <div class="metrics-value">
                {{ $toNumber(hangarStats.metrics.totalMinCrew, 'people') }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ $t('labels.hangarMetrics.totalMaxCrew') }}:
              </div>
              <div class="metrics-value">
                {{ $toNumber(hangarStats.metrics.totalMaxCrew, 'people') }}
              </div>
            </div>
            <div class="metrics-item">
              <div class="metrics-label">
                {{ $t('labels.hangarMetrics.totalCargo') }}:
              </div>
              <div class="metrics-value">
                {{ $toNumber(hangarStats.metrics.totalCargo, 'cargo') }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <FilteredList
      key="hangar"
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :hash="$route.hash"
      :paginated="true"
      :hide-loading="fleetchartVisible"
    >
      <template slot="actions">
        <BtnDropdown size="small">
          <template v-if="mobile">
            <Btn
              data-test="fleetchart-link"
              size="small"
              variant="dropdown"
              @click.native="toggleFleetchart"
            >
              <i class="fad fa-starship" />
              <span>{{ $t('labels.fleetchart') }}</span>
            </Btn>

            <Btn :to="{ name: 'hangar-stats' }" size="small" variant="dropdown">
              <i class="fad fa-chart-bar" />
              <span>{{ $t('labels.hangarStats') }}</span>
            </Btn>

            <ShareBtn
              v-if="currentUser && currentUser.publicHangar"
              :url="shareUrl"
              :title="metaTitle"
              size="small"
              variant="dropdown"
            />

            <hr />
          </template>

          <Btn
            :aria-label="toggleGridViewTooltip"
            size="small"
            variant="dropdown"
            @click.native="toggleGridView"
          >
            <i v-if="gridView" class="fad fa-list" />
            <i v-else class="fas fa-th" />
            <span>{{ toggleGridViewTooltip }}</span>
          </Btn>

          <Btn
            v-if="!gridView"
            :aria-label="toggleTableSlimTooltip"
            size="small"
            variant="dropdown"
            @click.native="toggleTableSlim"
          >
            <i v-if="tableSlim" class="fas fa-bars" />
            <i v-else class="fal fa-bars" />
            <span>{{ toggleTableSlimTooltip }}</span>
          </Btn>

          <Btn
            v-if="gridView"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="dropdown"
            @click.native="toggleDetails"
          >
            <i class="fad fa-info-square" />
            <span>{{ toggleDetailsTooltip }}</span>
          </Btn>

          <Btn
            v-if="!starterGuideVisible"
            :active="guideVisible"
            :aria-label="toggleGuideTooltip"
            size="small"
            variant="dropdown"
            @click.native="toggleGuide"
          >
            <i class="fad fa-question" />
            <span>{{ toggleGuideTooltip }}</span>
          </Btn>

          <hr />

          <Btn
            size="small"
            variant="dropdown"
            :aria-label="$t('actions.export')"
            @click.native="exportJson"
          >
            <i class="fal fa-download" />
            <span>{{ $t('actions.export') }}</span>
          </Btn>

          <HangarImportBtn size="small" variant="dropdown" @uploaded="fetch" />

          <hr />

          <Btn
            size="small"
            variant="dropdown"
            :disabled="deleting"
            :aria-label="$t('actions.hangar.destroyAll')"
            @click.native="destroyAll"
          >
            <i class="fal fa-trash" />
            <span>{{ $t('actions.hangar.destroyAll') }}</span>
          </Btn>
        </BtnDropdown>
      </template>

      <VehiclesFilterForm
        slot="filter"
        :hangar-groups-options="groupsCollection.records"
      />

      <HangarGuideBox v-if="isGuideVisible" />

      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          v-if="gridView"
          :records="records"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <VehiclePanel
              :vehicle="record"
              :details="detailsVisible"
              :editable="true"
              :highlight="record.hangarGroupIds.includes(highlightedGroup)"
            />
          </template>
        </FilteredGrid>

        <VehiclesTable
          v-else
          :vehicles="records"
          :primary-key="primaryKey"
          :editable="true"
          :slim="tableSlim"
        />

        <FleetchartApp
          :items="records"
          namespace="hangar"
          :loading="loading"
          download-name="my-hangar-fleetchart"
        />
      </template>
    </FilteredList>

    <PrimaryAction :label="$t('actions.addVehicle')" :action="showNewModal" />
  </section>
</template>

<script>
import { format } from 'date-fns'
import { mapGetters, mapActions } from 'vuex'
import debounce from 'lodash.debounce'
import FilteredList from '@/frontend/core/components/FilteredList/index.vue'
import FilteredGrid from '@/frontend/core/components/FilteredGrid/index.vue'
import VehiclesTable from '@/frontend/components/Vehicles/Table/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import PrimaryAction from '@/frontend/core/components/PrimaryAction/index.vue'
import BtnDropdown from '@/frontend/core/components/BtnDropdown/index.vue'
import VehiclePanel from '@/frontend/components/Vehicles/Panel/index.vue'
import HangarImportBtn from '@/frontend/components/HangarImportBtn/index.vue'
import VehiclesFilterForm from '@/frontend/components/Vehicles/FilterForm/index.vue'
import ModelClassLabels from '@/frontend/components/Models/ClassLabels/index.vue'
import GroupLabels from '@/frontend/components/Vehicles/GroupLabels/index.vue'
import FleetchartApp from '@/frontend/components/Fleetchart/App/index.vue'
import HangarGuideBox from '@/frontend/components/HangarGuideBox/index.vue'
import ShareBtn from '@/frontend/components/ShareBtn/index.vue'
import MetaInfo from '@/frontend/mixins/MetaInfo'
import vehiclesCollection from '@/frontend/api/collections/Vehicles'
import hangarGroupsCollection from '@/frontend/api/collections/HangarGroups'
import { displayAlert, displayConfirm } from '@/frontend/lib/Noty'

export default {
  name: 'HangarPage',

  components: {
    FilteredList,
    FilteredGrid,
    VehiclesTable,
    Btn,
    PrimaryAction,
    ShareBtn,
    BtnDropdown,
    HangarImportBtn,
    VehiclePanel,
    VehiclesFilterForm,
    ModelClassLabels,
    GroupLabels,
    HangarGuideBox,
    FleetchartApp,
  },

  mixins: [MetaInfo],

  data() {
    return {
      deleting: false,
      guideVisible: false,
      vehiclesChannel: null,
      highlightedGroup: null,
      collection: vehiclesCollection,
      groupsCollection: hangarGroupsCollection,
    }
  },

  computed: {
    ...mapGetters(['mobile']),
    ...mapGetters('session', ['currentUser']),
    ...mapGetters('hangar', [
      'detailsVisible',
      'gridView',
      'tableSlim',
      'perPage',
      'money',
      'starterGuideVisible',
      'fleetchartVisible',
    ]),

    hangarGroupCounts() {
      if (!this.hangarStats) {
        return []
      }

      return this.hangarStats.groups
    },
    hangarStats() {
      return this.collection.stats
    },
    toggleDetailsTooltip() {
      if (this.detailsVisible) {
        return this.$t('actions.hideDetails')
      }

      return this.$t('actions.showDetails')
    },
    toggleGridViewTooltip() {
      if (this.gridView) {
        return this.$t('actions.showTableView')
      }

      return this.$t('actions.showGridView')
    },
    toggleTableSlimTooltip() {
      if (this.tableSlim) {
        return this.$t('actions.showExpandedList')
      }

      return this.$t('actions.showCompactList')
    },
    toggleGuideTooltip() {
      if (this.guideVisible) {
        return this.$t('actions.hideGuide')
      }

      return this.$t('actions.showGuide')
    },
    shareUrl() {
      if (!this.currentUser) {
        return null
      }

      return this.currentUser.publicHangarUrl
    },
    isGuideVisible() {
      return this.starterGuideVisible || this.guideVisible
    },

    filters() {
      return {
        filters: this.$route.query.q,
        page: this.$route.query.page,
      }
    },
  },
  watch: {
    $route() {
      this.fetch()
    },

    perPage() {
      this.fetch()
    },
  },

  mounted() {
    this.fetch()
    this.setupUpdates()

    this.$comlink.$on('hangar-group-delete', this.fetch)
    this.$comlink.$on('hangar-group-save', this.groupsCollection.findAll)
  },

  beforeDestroy() {
    if (this.vehiclesChannel) {
      this.vehiclesChannel.unsubscribe()
    }

    this.$comlink.$off('hangar-group-delete')
    this.$comlink.$off('hangar-group-save')
  },

  methods: {
    ...mapActions('hangar', [
      'toggleDetails',
      'toggleMoney',
      'toggleGridView',
      'toggleTableSlim',
      'toggleFleetchart',
    ]),
    toggleGuide() {
      this.guideVisible = !this.guideVisible
    },

    showNewModal() {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/frontend/components/Vehicles/NewVehiclesModal'),
      })
    },

    highlightGroup(group) {
      if (!group) {
        this.highlightedGroup = null
        return
      }

      this.highlightedGroup = group.id
    },

    async fetch() {
      await this.collection.findAll(this.filters)
      await this.groupsCollection.findAll()
      await this.collection.findStats(this.filters)
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
          received: debounce(this.fetch, 500),
        }
      )
    },

    async exportJson() {
      const exportedData = await this.collection.export(this.filters)

      if (!exportedData || !window.URL) {
        displayAlert({ text: this.$t('messages.hangarExport.failure') })
        return
      }

      const link = document.createElement('a')

      link.href = window.URL.createObjectURL(new Blob([exportedData]))

      link.setAttribute(
        'download',
        `fleetyards-${this.currentUser.username}-hangar-${format(
          new Date(),
          'yyyy-MM-dd'
        )}.json`
      )

      document.body.appendChild(link)

      link.click()

      document.body.removeChild(link)
    },

    async destroyAll() {
      this.deleting = true

      displayConfirm({
        text: this.$t('messages.confirm.hangar.destroyAll'),
        onConfirm: async () => {
          await this.collection.destroyAll()

          this.$comlink.$emit('vehicles-delete-all')

          this.deleting = false
        },
        onClose: () => {
          this.deleting = false
        },
      })
    },
  },
}
</script>
