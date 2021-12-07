<template>
  <div>
    <FilteredList
      key="fleet-public-ships"
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :params="routeParams"
      :hash="$route.hash"
      :paginated="true"
    >
      <template slot="actions">
        <BtnDropdown size="small">
          <template v-if="mobile">
            <Btn
              size="small"
              variant="dropdown"
              data-test="fleetchart-link"
              @click.native="toggleFleetchart"
            >
              <i class="fad fa-starship" />
              <span>{{ $t('labels.fleetchart') }}</span>
            </Btn>

            <hr />
          </template>
          <Btn
            :active="detailsVisible"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="dropdown"
            @click.native="toggleDetails"
          >
            <i class="fad fa-info-square" />
            <span>{{ toggleDetailsTooltip }}</span>
          </Btn>

          <Btn size="small" variant="dropdown" @click.native="toggleGrouped">
            <template v-if="grouped">
              <i class="fas fa-square" />
              <span>{{ $t('actions.ungrouped') }}</span>
            </template>
            <template v-else>
              <i class="fas fa-th-large" />
              <span>{{ $t('actions.groupedByModel') }}</span>
            </template>
          </Btn>
        </BtnDropdown>
      </template>

      <PublicFleetVehiclesFilterForm slot="filter" />

      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          :records="records"
          :loading="loading"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <FleetVehiclePanel
              :fleet-vehicle="record"
              :details="detailsVisible"
              :show-owner="false"
            />
          </template>
        </FilteredGrid>
      </template>
    </FilteredList>

    <FleetchartApp
      :items="collection.records"
      namespace="publicFleet"
      :download-name="`${fleet.slug}-fleetchart`"
    />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import { Getter, Action } from 'vuex-class'
import FilteredList from 'frontend/core/components/FilteredList'
import FilteredGrid from 'frontend/core/components/FilteredGrid'
import Btn from 'frontend/core/components/Btn'
import BtnDropdown from 'frontend/core/components/BtnDropdown'
import FleetVehiclePanel from 'frontend/components/Fleets/VehiclePanel'
import FleetchartApp from 'frontend/components/Fleetchart/App'
import PublicFleetVehiclesFilterForm from 'frontend/components/Fleets/PublicFilterForm'
import ModelClassLabels from 'frontend/components/Models/ClassLabels'
import AddonsModal from 'frontend/components/Vehicles/AddonsModal'
import publicFleetVehiclesCollection from 'frontend/api/collections/PublicFleetVehicles'

@Component<FleetPublicShipsList>({
  components: {
    Btn,
    BtnDropdown,
    FilteredList,
    FilteredGrid,
    FleetVehiclePanel,
    ModelClassLabels,
    AddonsModal,
    PublicFleetVehiclesFilterForm,
    FleetchartApp,
  },
})
export default class FleetPublicShipsList extends Vue {
  collection: PublicFleetVehiclesCollection = publicFleetVehiclesCollection

  @Prop({ required: true }) fleet: Fleet

  @Getter('mobile') mobile

  @Getter('grouped', { namespace: 'fleet' }) grouped

  @Getter('detailsVisible', { namespace: 'fleet' }) detailsVisible

  @Action('toggleFleetchart', { namespace: 'fleet' }) toggleFleetchart: any

  get toggleDetailsTooltip() {
    if (this.detailsVisible) {
      return this.$t('actions.hideDetails')
    }
    return this.$t('actions.showDetails')
  }

  get routeParams() {
    return {
      ...this.$route.params,
      grouped: this.grouped,
    }
  }

  get filters() {
    return {
      slug: this.fleet.slug,
      grouped: this.grouped,
      page: this.$route.query.page,
    }
  }

  @Watch('grouped')
  onGroupedChange() {
    this.collection.findAll(this.filters)
  }

  toggleDetails() {
    this.$store.dispatch('fleet/toggleDetails')
  }

  toggleGrouped() {
    this.$store.dispatch('fleet/toggleGrouped')
  }
}
</script>
