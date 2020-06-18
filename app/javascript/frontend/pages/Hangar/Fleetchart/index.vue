<template>
  <section class="container hangar">
    <div class="row">
      <div class="col-xs-12 col-md-12">
        <div class="row">
          <div class="col-xs-12">
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
              v-if="statsCollection.record"
              :count-data="statsCollection.record.classifications"
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
          <div v-if="records.length" class="row">
            <div class="col-xs-12 col-md-4 col-md-offset-4 fleetchart-slider">
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

    <NewVehiclesModal ref="newVehiclesModal" />

    <PrimaryAction :label="$t('actions.addVehicle')" :action="showNewModal" />
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import FilteredList from 'frontend/components/FilteredList'
import Btn from 'frontend/components/Btn'
import Starship42Btn from 'frontend/components/Starship42Btn'
import PrimaryAction from 'frontend/components/PrimaryAction'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import FleetchartList from 'frontend/partials/Fleetchart/List'
import VehiclesFilterForm from 'frontend/partials/Vehicles/FilterForm'
import ModelClassLabels from 'frontend/partials/Models/ClassLabels'
import GroupLabels from 'frontend/partials/Vehicles/GroupLabels'
import VehicleModal from 'frontend/partials/Vehicles/Modal'
import AddonsModal from 'frontend/partials/Vehicles/AddonsModal'
import NewVehiclesModal from 'frontend/partials/Vehicles/NewVehiclesModal'
import FleetchartSlider from 'frontend/partials/Fleetchart/Slider'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Filters from 'frontend/mixins/Filters'
import vehiclesFleetchartCollection, {
  VehiclesFleetchartCollection,
} from 'frontend/collections/VehiclesFleetchart'
import hangarGroupsCollection, {
  HangarGroupsCollection,
} from 'frontend/collections/HangarGroups'
import hangarStatsCollection, {
  HangarStatsCollection,
} from 'frontend/collections/HangarStats'

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

  collection: VehiclesFleetchartCollection = vehiclesFleetchartCollection

  groupsCollection: HangarGroupsCollection = hangarGroupsCollection

  statsCollection: HangarStatsCollection = hangarStatsCollection

  @Getter('mobile') mobile

  @Getter('currentUser', { namespace: 'session' }) currentUser

  @Getter('fleetchartScale', { namespace: 'hangar' }) fleetchartScale

  get hangarGroupCounts() {
    if (!this.statsCollection.record) {
      return []
    }

    return this.statsCollection.record.groups
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
    this.$refs.vehicleModal.open(vehicle)
  }

  updateScale(value) {
    this.$store.commit('hangar/setFleetchartScale', value)
  }

  showNewModal() {
    this.$refs.newVehiclesModal.open()
  }

  showAddonsModal(vehicle) {
    this.$refs.addonsModal.open(vehicle)
  }

  async fetch() {
    await this.collection.findAll(this.filters)
    await this.groupsCollection.findAll()
    await this.statsCollection.current(this.filters)
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
