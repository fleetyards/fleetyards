<template>
  <div>
    <div class="row">
      <div class="col-12">
        <div class="page-actions page-actions-right">
          <Starship42Btn :vehicles="collection.records" />
        </div>
      </div>
    </div>

    <FilteredList
      key="fleet-public-fleetchart"
      :collection="collection"
      collection-method="findAllFleetchart"
      :name="$route.name"
      :route-query="$route.query"
      :params="$route.params"
      :hash="$route.hash"
      :paginated="true"
    >
      <PublicFleetVehiclesFilterForm slot="filter" />

      <template #actions>
        <Btn
          size="small"
          :active="fleetchartLabels"
          @click.native="toggleFleetchartLabel"
        >
          <i class="fad fa-tags" />
        </Btn>
        <Btn
          size="small"
          :active="fleetchartViewpoint === 'top'"
          @click.native="updateFleetchartViewpointTop"
        >
          <i class="fad fa-arrow-to-bottom" />
        </Btn>
        <Btn
          size="small"
          :active="fleetchartViewpoint === 'side'"
          @click.native="updateFleetchartViewpointSide"
        >
          <i class="fad fa-arrow-to-left" />
        </Btn>
      </template>

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
          :viewpoint="fleetchartViewpoint"
          :labels="fleetchartLabels"
        />
      </template>
    </FilteredList>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import FilteredList from 'frontend/core/components/FilteredList'
import Starship42Btn from 'frontend/components/Starship42Btn'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import FleetChartStatusBtn from 'frontend/components/FleetChartStatusBtn'
import FleetchartList from 'frontend/components/Fleetchart/List'
import AddonsModal from 'frontend/components/Vehicles/AddonsModal'
import FleetchartSlider from 'frontend/components/Fleetchart/Slider'
import publicFleetVehiclesCollection from 'frontend/api/collections/PublicFleetVehicles'
import PublicFleetVehiclesFilterForm from 'frontend/components/Fleets/PublicFilterForm'

@Component<FleetPublicFleetchart>({
  components: {
    Starship42Btn,
    FilteredList,
    DownloadScreenshotBtn,
    FleetChartStatusBtn,
    FleetchartList,
    AddonsModal,
    FleetchartSlider,
    PublicFleetVehiclesFilterForm,
  },
})
export default class FleetPublicFleetchart extends Vue {
  collection: PublicFleetVehiclesCollection = publicFleetVehiclesCollection

  @Prop({ required: true }) fleet: Fleet

  @Getter('publicFleetchartScale', { namespace: 'fleet' }) fleetchartScale

  @Getter('publicFleetchartViewpoint', { namespace: 'fleet' })
  fleetchartViewpoint

  @Getter('publicFleetchartLabels', { namespace: 'fleet' }) fleetchartLabels

  updateScale(value) {
    this.$store.commit('fleet/setPublicFleetchartScale', value)
  }

  updateFleetchartViewpointTop() {
    this.$store.commit('fleet/setPublicFleetchartViewpoint', 'top')
  }

  updateFleetchartViewpointSide() {
    this.$store.commit('fleet/setPublicFleetchartViewpoint', 'side')
  }

  toggleFleetchartLabel() {
    this.$store.commit(
      'fleet/setPublicFleetchartLabels',
      !this.fleetchartLabels,
    )
  }
}
</script>
