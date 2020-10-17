<template>
  <section class="container fleet-detail">
    <div v-if="fleet" class="row">
      <div class="col-12 col-lg-8">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 class="sr-only">{{ fleet.name }} ({{ fleet.fid }})</h1>
      </div>
    </div>

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
        <div class="page-actions page-actions-right">
          <Starship42Btn :vehicles="collection.records" />
        </div>
      </div>
    </div>

    <FilteredList
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
              variant="link"
              :with-icon="true"
            />

            <hr />
          </template>

          <DownloadScreenshotBtn
            v-if="fleet"
            element="#fleetchart"
            :filename="`${fleet.slug}-fleetchart`"
            size="small"
            variant="link"
            :show-tooltip="false"
          />
        </BtnDropdown>
      </template>

      <FleetVehiclesFilterForm slot="filter" />

      <template #default="{ records }">
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

        <FleetchartList :items="records" :scale="fleetchartScale" />
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import FilteredList from 'frontend/core/components/FilteredList'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import Starship42Btn from 'frontend/components/Starship42Btn'
import DownloadScreenshotBtn from 'frontend/components/DownloadScreenshotBtn'
import FleetchartList from 'frontend/components/Fleetchart/List'
import FleetVehiclesFilterForm from 'frontend/components/Fleets/FilterForm'
import ModelClassLabels from 'frontend/components/Models/ClassLabels'
import AddonsModal from 'frontend/components/Vehicles/AddonsModal'
import FleetchartSlider from 'frontend/components/Fleetchart/Slider'
import MetaInfo from 'frontend/mixins/MetaInfo'
import HangarItemsMixin from 'frontend/mixins/HangarItems'
import { fleetRouteGuard } from 'frontend/utils/RouteGuards'
import fleetVehiclesCollection from 'frontend/api/collections/FleetVehicles'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import fleetsCollection from 'frontend/api/collections/Fleets'

@Component<FleetFleetchart>({
  components: {
    Btn,
    BtnDropdown,
    BreadCrumbs,
    Starship42Btn,
    FilteredList,
    DownloadScreenshotBtn,
    FleetchartList,
    ModelClassLabels,
    AddonsModal,
    FleetVehiclesFilterForm,
    FleetchartSlider,
  },
  mixins: [MetaInfo, HangarItemsMixin],
  beforeRouteEnter: fleetRouteGuard,
})
export default class FleetFleetchart extends Vue {
  collection: FleetVehiclesCollection = fleetVehiclesCollection

  @Getter('fleetchartScale', { namespace: 'fleet' }) fleetchartScale

  @Getter('mobile') mobile

  @Getter('money', { namespace: 'fleet' }) money

  get fleet() {
    return fleetsCollection.record
  }

  get metaTitle() {
    if (!this.fleet) {
      return null
    }

    return this.fleet.name
  }

  get crumbs() {
    if (!this.fleet) {
      return []
    }

    return [
      {
        to: {
          name: 'fleet',
          params: {
            slug: this.fleet.slug,
          },
        },
        label: this.fleet.name,
      },
    ]
  }

  get fleetStats() {
    return this.collection.stats
  }

  get filters() {
    return {
      slug: this.$route.params.slug,
      filters: this.$route.query.q,
    }
  }

  mounted() {
    this.fetchFleet()
    this.fetch()
  }

  toggleGrouped() {
    this.$store.dispatch('fleet/toggleGrouped')
  }

  toggleMoney() {
    this.$store.dispatch('fleet/toggleMoney')
  }

  updateScale(value) {
    this.$store.commit('fleet/setFleetchartScale', value)
  }

  async fetch() {
    await this.collection.findStats(this.filters)
  }

  async fetchFleet() {
    await fleetsCollection.findBySlug(this.$route.params.slug)
  }
}
</script>
