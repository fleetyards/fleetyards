<template>
  <section class="container hangar">
    <div class="row">
      <div class="col-12 col-lg-12">
        <div class="row">
          <div class="col-12">
            <BreadCrumbs
              :crumbs="[{ to: { name: 'hangar' }, label: $t('nav.hangar') }]"
            />
            <h1 class="sr-only">
              {{ $t('headlines.hangar.fleetchart') }}
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
              v-if="groupsCollection.records.length"
              :hangar-groups="groupsCollection.records"
              :hangar-group-counts="hangarGroupCounts"
              :label="$t('labels.groups')"
            />
          </div>
          <div v-if="!mobile" class="page-actions page-actions-right">
            <Starship42Btn :vehicles="collection.records" />
            <ShareBtn
              v-if="currentUser && currentUser.publicHangar"
              :url="shareUrl"
              :title="metaTitle"
            />
          </div>
        </div>
      </div>
    </div>

    <FilteredList
      key="hangar-fleetchart"
      :collection="collection"
      collection-method="findAllFleetchart"
      :name="$route.name"
      :route-query="$route.query"
      :hash="$route.hash"
    >
      <template #actions="{ records }">
        <BtnDropdown size="small">
          <template v-if="mobile">
            <Starship42Btn
              :vehicles="records"
              size="small"
              variant="dropdown"
              :with-icon="true"
            />

            <hr />
          </template>

          <DownloadScreenshotBtn
            element="#fleetchart"
            filename="my-hangar-fleetchart"
            size="small"
            variant="dropdown"
          />

          <hr />

          <FleetChartStatusBtn size="small" variant="dropdown" />
        </BtnDropdown>
      </template>

      <VehiclesFilterForm
        slot="filter"
        :hangar-groups-options="groupsCollection.records"
      />

      <template #default="{ records }">
        <transition name="fade" appear>
          <div v-if="records.length" class="row justify-content-lg-center">
            <div class="col-12 col-lg-4">
              <FleetchartSlider
                :initial-scale="fleetchartScale"
                @change="updateScale"
              />
            </div>
          </div>
        </transition>

        <FleetchartList
          :items="records"
          :scale="fleetchartScale"
          :my-ship="true"
        />
      </template>
    </FilteredList>

    <PrimaryAction :label="$t('actions.addVehicle')" :action="showNewModal" />
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import FilteredList from 'frontend/core/components/FilteredList'
import Btn from 'frontend/core/components/Btn'
import Starship42Btn from 'frontend/components/Starship42Btn'
import ShareBtn from 'frontend/components/ShareBtn'
import PrimaryAction from 'frontend/core/components/PrimaryAction'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import FleetChartStatusBtn from 'frontend/components/FleetChartStatusBtn'
import FleetchartList from 'frontend/components/Fleetchart/List'
import VehiclesFilterForm from 'frontend/components/Vehicles/FilterForm'
import ModelClassLabels from 'frontend/components/Models/ClassLabels'
import GroupLabels from 'frontend/components/Vehicles/GroupLabels'
import VehicleModal from 'frontend/components/Vehicles/Modal'
import AddonsModal from 'frontend/components/Vehicles/AddonsModal'
import NewVehiclesModal from 'frontend/components/Vehicles/NewVehiclesModal'
import FleetchartSlider from 'frontend/components/Fleetchart/Slider'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Filters from 'frontend/mixins/Filters'
import vehiclesCollection, {
  VehiclesCollection,
} from 'frontend/api/collections/Vehicles'
import hangarGroupsCollection, {
  HangarGroupsCollection,
} from 'frontend/api/collections/HangarGroups'

@Component<HangarFleetchart>({
  components: {
    FilteredList,
    Btn,
    BreadCrumbs,
    BtnDropdown,
    Starship42Btn,
    ShareBtn,
    PrimaryAction,
    DownloadScreenshotBtn,
    FleetChartStatusBtn,
    FleetchartList,
    VehiclesFilterForm,
    ModelClassLabels,
    GroupLabels,
    VehicleModal,
    AddonsModal,
    NewVehiclesModal,
    FleetchartSlider,
  },
  mixins: [MetaInfo, Filters],
})
export default class HangarFleetchart extends Vue {
  get hangarGroupCounts(): HangarGroupMetrics[] {
    if (!this.hangarStats) {
      return []
    }

    return this.hangarStats.groups
  }

  get shareUrl() {
    if (!this.currentUser) {
      return null
    }

    return this.currentUser.publicHangarUrl
  }

  get hangarStats(): VehicleStats | null {
    return this.collection.stats
  }

  get filters() {
    return {
      filters: this.$route.query.q,
    }
  }

  deleting: boolean = false

  guideVisible: boolean = false

  vehiclesChannel = null

  collection: VehiclesCollection = vehiclesCollection

  groupsCollection: HangarGroupsCollection = hangarGroupsCollection

  @Getter('mobile') mobile

  @Getter('currentUser', { namespace: 'session' }) currentUser

  @Getter('fleetchartScale', { namespace: 'hangar' }) fleetchartScale

  @Watch('$route')
  onRouteChange() {
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

  updateScale(value) {
    this.$store.commit('hangar/setFleetchartScale', value)
  }

  showNewModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/NewVehiclesModal'),
    })
  }

  async fetch() {
    await this.collection.findAllFleetchart(this.filters)
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
}
</script>
