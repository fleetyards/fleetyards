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

            <Btn
              v-if="currentUser && currentUser.publicHangar"
              v-tooltip="$t('actions.share')"
              @click.native="share"
            >
              <i class="fad fa-share-square" />
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
              variant="dropdown"
            >
              <i class="fad fa-starship" />
              <span>{{ $t('labels.fleetchart') }}</span>
            </Btn>

            <Btn :to="{ name: 'hangar-stats' }" size="small" variant="dropdown">
              <i class="fad fa-chart-bar" />
              <span>{{ $t('labels.hangarStats') }}</span>
            </Btn>

            <Btn
              v-if="currentUser && currentUser.publicHangar"
              size="small"
              variant="dropdown"
              @click.native="share"
            >
              <i class="fad fa-share-square" />
              <span>{{ $t('actions.share') }}</span>
            </Btn>

            <hr />
          </template>

          <Btn
            :aria-label="toggleGridView"
            size="small"
            variant="dropdown"
            @click.native="toggleGridView"
          >
            <i v-if="gridView" class="fad fa-list" />
            <i v-else class="fas fa-th" />
            <span>{{ toggleGridViewTooltip }}</span>
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

      <template #default="{ records, filterVisible, primaryKey }">
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
        />
      </template>
    </FilteredList>

    <portal to="navigation-mobile-extras">
      <Btn variant="link" :inline="true" @click.native="showNewModal">
        <i class="fa fa-plus" />
      </Btn>
    </portal>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter, Action } from 'vuex-class'
import FilteredList from 'frontend/core/components/FilteredList'
import FilteredGrid from 'frontend/core/components/FilteredGrid'
import copyText from 'frontend/utils/CopyText'
import VehiclesTable from 'frontend/components/Vehicles/Table'
import Btn from 'frontend/core/components/Btn'
import PrimaryAction from 'frontend/core/components/PrimaryAction'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import VehiclePanel from 'frontend/components/Vehicles/Panel'
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
import { displayAlert, displayConfirm, displaySuccess } from 'frontend/lib/Noty'
import debounce from 'lodash.debounce'

@Component<Hangar>({
  components: {
    FilteredList,
    FilteredGrid,
    VehiclesTable,
    Btn,
    PrimaryAction,
    BtnDropdown,
    HangarImportBtn,
    VehiclePanel,
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

  get shareUrl() {
    if (!this.currentUser) {
      return null
    }

    return this.currentUser.publicHangarUrl
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
        received: debounce(this.fetch, 500),
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

  share() {
    if (navigator.canShare && navigator.canShare({ url: this.shareUrl })) {
      navigator
        .share({
          title: this.metaTitle,
          url: this.shareUrl,
        })
        .then(() => console.info('Share was successful.'))
        .catch(error => console.info('Sharing failed', error))
    } else {
      this.copyShareUrl()
    }
  }

  copyShareUrl() {
    if (!this.shareUrl) {
      displayAlert({
        text: this.$t('messages.copyShareUrl.failure'),
      })
    }

    copyText(this.shareUrl).then(
      () => {
        displaySuccess({
          text: this.$t('messages.copyShareUrl.success', {
            url: this.shareUrl,
          }),
        })
      },
      () => {
        displayAlert({
          text: this.$t('messages.copyShareUrl.failure'),
        })
      },
    )
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
