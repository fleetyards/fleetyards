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
          <div v-if="!mobile" class="page-actions">
            <Starship42Btn :vehicles="collection.records" />
          </div>
        </div>
      </div>
    </div>

    <FilteredList
      :collection="collection"
      collection-method="findAllFleetchart"
      :name="$route.name"
      :route-query="$route.query"
      :hash="$route.hash"
    >
      <template v-slot:actions="{ records }">
        <Starship42Btn v-if="mobile" :vehicles="records" size="small" />
        <DownloadScreenshotBtn
          element="#fleetchart"
          filename="my-hangar-fleetchart"
          size="small"
          :with-label="false"
        />
      </template>

      <VehiclesFilterForm
        slot="filter"
        :hangar-groups-options="groupsCollection.records"
      />

      <template v-slot:default="{ records }">
        <transition name="fade" appear>
          <div v-if="records.length" class="row justify-content-lg-center">
            <div class="col-12 col-lg-4 fleetchart-slider">
              <FleetchartSlider
                :initial-scale="fleetchartScale"
                @change="updateScale"
              />
            </div>
          </div>
        </transition>

        <FleetchartList
          :items="records"
          :on-edit="showEditModal"
          :on-addons="showAddonsModal"
          :scale="fleetchartScale"
        />
      </template>
    </FilteredList>

    <VehicleModal
      ref="vehicleModal"
      :collection="collection"
      :hangar-groups="groupsCollection.records"
    />

    <AddonsModal ref="addonsModal" :modifiable="true" />

    <NewVehiclesModal ref="newVehiclesModal" :collection="collection" />

    <PrimaryAction :label="$t('actions.addVehicle')" :action="showNewModal" />
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import FilteredList from 'frontend/core/components/FilteredList'
import Btn from 'frontend/core/components/Btn'
import Starship42Btn from 'frontend/components/Starship42Btn'
import PrimaryAction from 'frontend/core/components/PrimaryAction'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
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
    Starship42Btn,
    PrimaryAction,
    DownloadScreenshotBtn,
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
  deleting: boolean = false

  guideVisible: boolean = false

  vehiclesChannel = null

  collection: VehiclesCollection = vehiclesCollection

  groupsCollection: HangarGroupsCollection = hangarGroupsCollection

  @Getter('mobile') mobile

  @Getter('currentUser', { namespace: 'session' }) currentUser

  @Getter('fleetchartScale', { namespace: 'hangar' }) fleetchartScale

  get hangarGroupCounts(): HangarGroupMetrics[] {
    if (!this.hangarStats) {
      return []
    }

    return this.hangarStats.groups
  }

  get hangarStats(): VehicleStats | null {
    return this.collection.stats
  }

  get filters() {
    return {
      filters: this.$route.query.q,
    }
  }

  @Watch('$route')
  onRouteChange() {
    this.fetch()
  }

  mounted() {
    this.fetch()
    this.setupUpdates()

    this.$comlink.$on('hangarGroupDelete', this.fetch)
    this.$comlink.$on('hangarGroupSave', this.groupsCollection.findAll)
  }

  beforeDestroy() {
    if (this.vehiclesChannel) {
      this.vehiclesChannel.unsubscribe()
    }

    this.$comlink.$off('hangarGroupDelete')
    this.$comlink.$off('hangarGroupSave')
  }

  showEditModal(vehicle) {
    if (!this.$refs.vehicleModal) {
      return
    }

    this.$refs.vehicleModal.open(vehicle)
  }

  updateScale(value) {
    this.$store.commit('hangar/setFleetchartScale', value)
  }

  showNewModal() {
    if (!this.$refs.newVehiclesModal) {
      return
    }

    this.$refs.newVehiclesModal.open()
  }

  showAddonsModal(vehicle) {
    if (!this.$refs.addonsModal) {
      return
    }

    this.$refs.addonsModal.open(vehicle)
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
