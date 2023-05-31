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
      :hide-loading="fleetchartVisible"
    >
      <template #actions>
        <BtnDropdown size="small">
          <template v-if="mobile">
            <Btn
              size="small"
              variant="dropdown"
              data-test="fleetchart-link"
              @click.native="toggleFleetchart"
            >
              <i class="fad fa-starship" />
              <span>{{ $t("labels.fleetchart") }}</span>
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
              <span>{{ $t("actions.ungrouped") }}</span>
            </template>
            <template v-else>
              <i class="fas fa-th-large" />
              <span>{{ $t("actions.groupedByModel") }}</span>
            </template>
          </Btn>
        </BtnDropdown>
      </template>

      <PublicFleetVehiclesFilterForm slot="filter" />

      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          :records="records"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <FleetVehiclePanel
              :fleet-vehicle="record"
              :model-counts="modelCounts"
              :fleet-slug="fleet.slug"
              :details="detailsVisible"
              :show-owner="false"
            />
          </template>
        </FilteredGrid>

        <FleetchartApp
          :items="records"
          namespace="publicFleet"
          :loading="loading"
          :download-name="`${fleet.slug}-fleetchart`"
        />
      </template>
    </FilteredList>
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop, Watch } from "vue-property-decorator";
import { Getter, Action } from "vuex-class";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilteredGrid from "@/frontend/core/components/FilteredGrid/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
import FleetVehiclePanel from "@/frontend/components/Fleets/VehiclePanel/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import PublicFleetVehiclesFilterForm from "@/frontend/components/Fleets/PublicFilterForm/index.vue";
import ModelClassLabels from "@/frontend/components/Models/ClassLabels/index.vue";
import AddonsModal from "@/frontend/components/Vehicles/AddonsModal/index.vue";
import publicFleetVehiclesCollection from "@/frontend/api/collections/PublicFleetVehicles";

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
  collection: PublicFleetVehiclesCollection = publicFleetVehiclesCollection;

  @Prop({ required: true }) fleet: Fleet;

  @Getter("mobile") mobile;

  @Getter("grouped", { namespace: "publicFleet" }) grouped;

  @Getter("detailsVisible", { namespace: "publicFleet" }) detailsVisible;

  @Getter("fleetchartVisible", { namespace: "publicFleet" }) fleetchartVisible;

  @Getter("perPage", { namespace: "publicFleet" }) perPage;

  @Action("toggleFleetchart", { namespace: "publicFleet" })
  toggleFleetchart: any;

  @Action("toggleDetails", { namespace: "publicFleet" }) toggleDetails: any;

  @Action("toggleGrouped", { namespace: "publicFleet" }) toggleGrouped: any;

  get toggleDetailsTooltip() {
    if (this.detailsVisible) {
      return this.$t("actions.hideDetails");
    }
    return this.$t("actions.showDetails");
  }

  get routeParams() {
    return {
      ...this.$route.params,
      grouped: this.grouped,
    };
  }

  get filters() {
    return {
      slug: this.fleet.slug,
      grouped: this.grouped,
      page: this.$route.query.page,
    };
  }

  get modelCounts() {
    return this.collection.modelCounts;
  }

  @Watch("grouped")
  onGroupedChange() {
    this.fetch();
  }

  @Watch("perPage")
  onPerPageChange() {
    this.fetch();
  }

  @Watch("$route")
  onRouteChange() {
    this.fetchModelCounts();
  }

  @Watch("fleet")
  onFleetChange() {
    this.fetchModelCounts();
  }

  mounted() {
    this.fetchModelCounts();
  }

  async fetch() {
    await this.collection.findAll(this.filters);
  }

  async fetchModelCounts() {
    await this.collection.findModelCounts(this.filters);
  }
}
</script>
