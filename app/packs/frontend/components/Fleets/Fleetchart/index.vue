<template>
  <div>
    <div class="row">
      <div class="col-12 col-lg-8">
        <ModelClassLabels
          v-if="fleetStats"
          :label="$t('labels.fleet.classes')"
          :count-data="fleetStats.classifications"
          filter-key="classificationIn"
        />
      </div>
      <div class="col-12 col-lg-4">
        <div v-if="!mobile" class="page-actions page-actions-right">
          <Starship42Btn v-if="!mobile" :vehicles="collection.records" />

          <Btn
            v-if="fleet.publicFleet"
            v-tooltip="$t('actions.copyPublicUrl')"
            @click.native="copyPublicUrl"
          >
            <i class="fad fa-share-square" />
          </Btn>
        </div>
      </div>
    </div>

    <FilteredList
      key="fleet-fleetchart"
      :collection="collection"
      collection-method="findAllFleetchart"
      :name="$route.name"
      :route-query="$route.query"
      :params="$route.params"
      :hash="$route.hash"
      :paginated="true"
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

            <Btn
              v-if="fleet.publicFleet"
              size="small"
              variant="dropdown"
              @click.native="copyPublicUrl"
            >
              <i class="fad fa-share-square" />
              <span>{{ $t('actions.copyPublicUrl') }}</span>
            </Btn>

            <hr />
          </template>

          <DownloadScreenshotBtn
            v-if="fleet"
            element="#fleetchart"
            :filename="`${fleet.slug}-fleetchart`"
            size="small"
            variant="dropdown"
            :show-tooltip="false"
          />

          <hr />

          <FleetChartStatusBtn size="small" variant="dropdown" />
        </BtnDropdown>
      </template>

      <FleetVehiclesFilterForm slot="filter" />

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
import copyText from 'frontend/utils/CopyText'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import Starship42Btn from 'frontend/components/Starship42Btn'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import FleetChartStatusBtn from 'frontend/components/FleetChartStatusBtn'
import FleetchartList from 'frontend/components/Fleetchart/List'
import FleetVehiclesFilterForm from 'frontend/components/Fleets/FilterForm'
import ModelClassLabels from 'frontend/components/Models/ClassLabels'
import AddonsModal from 'frontend/components/Vehicles/AddonsModal'
import FleetchartSlider from 'frontend/components/Fleetchart/Slider'
import fleetVehiclesCollection from 'frontend/api/collections/FleetVehicles'
import { displayAlert, displaySuccess } from 'frontend/lib/Noty'

@Component<FleetFleetchart>({
  components: {
    Btn,
    BtnDropdown,
    Starship42Btn,
    FilteredList,
    DownloadScreenshotBtn,
    FleetChartStatusBtn,
    FleetchartList,
    ModelClassLabels,
    AddonsModal,
    FleetVehiclesFilterForm,
    FleetchartSlider,
  },
})
export default class FleetFleetchart extends Vue {
  collection: FleetVehiclesCollection = fleetVehiclesCollection

  @Prop({ required: true }) fleet: Fleet

  @Getter('fleetchartScale', { namespace: 'fleet' }) fleetchartScale

  @Getter('mobile') mobile

  get fleetStats() {
    return this.collection.stats
  }

  get filters() {
    return {
      slug: this.$route.params.slug,
      filters: this.$route.query.q,
    }
  }

  get publicUrl() {
    if (!this.fleet) {
      return ''
    }
    const host = `${window.location.protocol}//${window.location.host}`

    return `${host}/fleets/${this.fleet.slug}/fleetchart`
  }

  mounted() {
    this.fetch()
  }

  updateScale(value) {
    this.$store.commit('fleet/setFleetchartScale', value)
  }

  async fetch() {
    await this.collection.findStats(this.filters)
  }

  copyPublicUrl(_event) {
    copyText(this.publicUrl).then(
      () => {
        displaySuccess({
          text: this.$t('messages.copyPublicUrl.success', {
            publicUrl: this.publicUrl,
          }),
        })
      },
      () => {
        displayAlert({
          text: this.$t('messages.copyPublicUrl.failure'),
        })
      }
    )
  }
}
</script>
