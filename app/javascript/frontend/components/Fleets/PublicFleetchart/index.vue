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

        <FleetchartList :items="records" :scale="fleetchartScale" />
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

@Component<FleetPublicFleetchart>({
  components: {
    Starship42Btn,
    FilteredList,
    DownloadScreenshotBtn,
    FleetChartStatusBtn,
    FleetchartList,
    AddonsModal,
    FleetchartSlider,
  },
})
export default class FleetPublicFleetchart extends Vue {
  collection: PublicFleetVehiclesCollection = publicFleetVehiclesCollection

  @Prop({ required: true }) fleet: Fleet

  @Getter('fleetchartScale', { namespace: 'fleet' }) fleetchartScale

  updateScale(value) {
    this.$store.commit('fleet/setFleetchartScale', value)
  }
}
</script>
