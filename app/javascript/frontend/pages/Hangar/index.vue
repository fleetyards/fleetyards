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
              :hangar-groups="groupsCollection.records"
              :hangar-group-counts="hangarGroupCounts"
              :label="$t('labels.groups')"
              @highlight="highlightGroup"
            />
          </div>
          <div v-if="!mobile" class="page-actions page-actions-right">
            <Btn
              :to="{ name: 'hangar-fleetchart' }"
              data-test="fleetchart-link"
            >
              <i class="fad fa-starship" />
              {{ $t('labels.fleetchart') }}
            </Btn>

            <Btn :to="{ name: 'hangar-stats' }">
              <i class="fal fa-chart-bar" />
              {{ $t('labels.hangarStats') }}
            </Btn>

            <Btn :href="publicUrl">
              {{ $t('labels.publicUrl') }}
            </Btn>
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
    >
      <template slot="actions">
        <BtnDropdown size="small">
          <template v-if="mobile">
            <Btn
              :to="{ name: 'hangar-fleetchart' }"
              size="small"
              variant="link"
            >
              <i class="fad fa-starship" />
              {{ $t('labels.fleetchart') }}
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

          <Btn
            :aria-label="toggleGridView"
            size="small"
            variant="link"
            @click.native="toggleGridView"
          >
            <i v-if="gridView" class="fad fa-list" />
            <i v-else class="fas fa-th" />
            {{ toggleGridViewTooltip }}
          </Btn>

          <Btn
            v-if="gridView"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="link"
            @click.native="toggleDetails"
          >
            <i class="fad fa-info-square" />
            {{ toggleDetailsTooltip }}
          </Btn>

          <Btn
            v-if="!starterGuideVisible"
            :active="guideVisible"
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

      <VehiclesFilterForm
        slot="filter"
        :hangar-groups-options="groupsCollection.records"
      />

      <HangarGuideBox v-if="isGuideVisible" />

      <template #default="{ records, filterVisible, primaryKey }">
        <FilteredGrid
          v-if="gridView"
          :records="records"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <ModelPanel
              :model="record.model"
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
        />
      </template>
    </FilteredList>

    <PrimaryAction :label="$t('actions.addVehicle')" :action="showNewModal" />
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter, Action } from 'vuex-class'
import FilteredList from 'frontend/core/components/FilteredList'
import FilteredGrid from 'frontend/core/components/FilteredGrid'
import VehiclesTable from 'frontend/components/Vehicles/Table'
import Btn from 'frontend/core/components/Btn'
import PrimaryAction from 'frontend/core/components/PrimaryAction'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import ModelPanel from 'frontend/components/Models/Panel'
import HangarImportBtn from 'frontend/components/HangarImportBtn'
import VehiclesFilterForm from 'frontend/components/Vehicles/FilterForm'
import ModelClassLabels from 'frontend/components/Models/ClassLabels'
import GroupLabels from 'frontend/components/Vehicles/GroupLabels'
import HangarGuideBox from 'frontend/components/HangarGuideBox'
import AddonsModal from 'frontend/components/Vehicles/AddonsModal'
import MetaInfo from 'frontend/mixins/MetaInfo'
import HangarItemsMixin from 'frontend/mixins/HangarItems'
import { format } from 'date-fns'
import vehiclesCollection from 'frontend/api/collections/Vehicles'
import hangarGroupsCollection from 'frontend/api/collections/HangarGroups'
import { displayAlert, displayConfirm } from 'frontend/lib/Noty'

@Component<Hangar>({
  components: {
    FilteredList,
    FilteredGrid,
    VehiclesTable,
    Btn,
    PrimaryAction,
    BtnDropdown,
    HangarImportBtn,
    ModelPanel,
    VehiclesFilterForm,
    ModelClassLabels,
    GroupLabels,
    HangarGuideBox,
    AddonsModal,
  },
  mixins: [MetaInfo, HangarItemsMixin],
})
export default class Hangar extends Vue {
  deleting: boolean = false

  guideVisible: boolean = false

  vehiclesChannel = null

  highlightedGroup: string = null

  collection: VehiclesCollection = vehiclesCollection

  groupsCollection: HangarGroupsCollection = hangarGroupsCollection

  @Getter('mobile') mobile

  @Getter('currentUser', { namespace: 'session' }) currentUser

  @Getter('detailsVisible', { namespace: 'hangar' }) detailsVisible

  @Getter('gridView', { namespace: 'hangar' }) gridView

  @Getter('perPage', { namespace: 'hangar' }) perPage

  @Getter('money', { namespace: 'hangar' }) money

  @Getter('starterGuideVisible', { namespace: 'hangar' }) starterGuideVisible

  @Action('toggleDetails', { namespace: 'hangar' }) toggleDetails: any

  @Action('toggleMoney', { namespace: 'hangar' }) toggleMoney: any

  @Action('toggleGridView', { namespace: 'hangar' }) toggleGridView: any

  get hangarGroupCounts(): HangarGroupMetrics[] {
    if (!this.hangarStats) {
      return []
    }

    return this.hangarStats.groups
  }

  get hangarStats(): VehicleStats | null {
    return this.collection.stats
  }

  get toggleDetailsTooltip() {
    if (this.detailsVisible) {
      return this.$t('actions.hideDetails')
    }
    return this.$t('actions.showDetails')
  }

  get toggleGridViewTooltip() {
    if (this.gridView) {
      return this.$t('actions.showTableView')
    }
    return this.$t('actions.showGridView')
  }

  get toggleGuideTooltip() {
    if (this.guideVisible) {
      return this.$t('actions.hideGuide')
    }
    return this.$t('actions.showGuide')
  }

  get publicUrl() {
    if (!this.currentUser) {
      return ''
    }
    return `/hangar/${this.currentUser.username}`
  }

  get isGuideVisible() {
    return this.starterGuideVisible || this.guideVisible
  }

  get filters() {
    return {
      filters: this.$route.query.q,
      page: this.$route.query.page,
    }
  }

  @Watch('$route')
  onRouteChange() {
    this.fetch()
  }

  @Watch('perPage')
  onPerPageChange() {
    this.fetch()
  }

  mounted() {
    this.fetch()
    this.setupUpdates()

    this.$comlink.$on('hangar-group-delete', this.fetch)
    this.$comlink.$on('hangar-group-save', this.groupsCollection.findAll)
  }

  beforeDestroy() {
    if (this.vehiclesChannel) {
      this.vehiclesChannel.unsubscribe()
    }

    this.$comlink.$off('hangar-group-delete')
    this.$comlink.$off('hangar-group-save')
  }

  toggleGuide() {
    this.guideVisible = !this.guideVisible
  }

  showNewModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/NewVehiclesModal'),
    })
  }

  highlightGroup(group) {
    if (!group) {
      this.highlightedGroup = null
      return
    }

    this.highlightedGroup = group.id
  }

  async fetch() {
    await this.collection.findAll(this.filters)
    await this.groupsCollection.findAll()
    await this.collection.findStats(this.filters)
  }

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
  }

  async exportJson() {
    const exportedData = await this.collection.export(this.filters)

    // eslint-disable-next-line compat/compat
    if (!exportedData || !window.URL) {
      displayAlert({ text: this.$t('messages.hangarExport.failure') })
      return
    }

    const link = document.createElement('a')

    // eslint-disable-next-line compat/compat
    link.href = window.URL.createObjectURL(new Blob([exportedData]))

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
  }

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
  }
}
</script>
