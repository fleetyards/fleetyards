<template>
  <div class="row">
    <div class="col-12 col-lg-12">
      <div class="fleet-header">
        <div class="fleet-labels">
          <ModelClassLabels
            v-if="fleetStats"
            :label="$t('labels.fleet.classes')"
            :count-data="fleetStats.classifications"
            filter-key="classificationIn"
          />
        </div>
      </div>

      <div v-if="fleetStats && fleetStats.metrics && !mobile" class="row">
        <div class="col-12 fleet-metrics metrics-block" @click="toggleMoney">
          <div v-if="money" class="metrics-item">
            <div class="metrics-label">
              {{ $t("labels.hangarMetrics.totalMoney") }}:
            </div>
            <div class="metrics-value">
              {{ $toDollar(fleetStats.metrics.totalMoney) }}
            </div>
          </div>
          <div v-if="money" class="metrics-item">
            <div class="metrics-label">
              {{ $t("labels.hangarMetrics.totalCredits") }}:
            </div>
            <div class="metrics-value">
              <span v-html="$toUEC(fleetStats.metrics.totalCredits)" />
            </div>
          </div>
          <div class="metrics-item">
            <div class="metrics-label">
              {{ $t("labels.hangarMetrics.total") }}:
            </div>
            <div class="metrics-value">
              {{ $toNumber(fleetStats.total, "ships") }}
            </div>
          </div>
          <div class="metrics-item">
            <div class="metrics-label">
              {{ $t("labels.hangarMetrics.totalMinCrew") }}:
            </div>
            <div class="metrics-value">
              {{ $toNumber(fleetStats.metrics.totalMinCrew, "people") }}
            </div>
          </div>
          <div class="metrics-item">
            <div class="metrics-label">
              {{ $t("labels.hangarMetrics.totalMaxCrew") }}:
            </div>
            <div class="metrics-value">
              {{ $toNumber(fleetStats.metrics.totalMaxCrew, "people") }}
            </div>
          </div>
          <div class="metrics-item">
            <div class="metrics-label">
              {{ $t("labels.hangarMetrics.totalCargo") }}:
            </div>
            <div class="metrics-value">
              {{ $toNumber(fleetStats.metrics.totalCargo, "cargo") }}
            </div>
          </div>
        </div>
      </div>

      <FilteredList
        key="fleet-ships"
        :collection="collection"
        :name="$route.name"
        :route-query="$route.query"
        :params="routeParams"
        :hash="$route.hash"
        :paginated="true"
        :hide-loading="fleetchartVisible"
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
                <span>{{ $t("labels.fleetchart") }}</span>
              </Btn>

              <ShareBtn
                v-if="fleet.publicFleet"
                :url="shareUrl"
                :title="metaTitle"
                size="small"
                variant="dropdown"
              />

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
                <i class="fas fa-object-intersect" />
                <span>{{ $t("actions.ungrouped") }}</span>
              </template>
              <template v-else>
                <i class="fas fa-object-union" />
                <span>{{ $t("actions.groupedByModel") }}</span>
              </template>
            </Btn>

            <Btn
              size="small"
              variant="dropdown"
              :aria-label="$t('actions.export')"
              @click.native="exportJson"
            >
              <i class="fal fa-download" />
              <span>{{ $t("actions.export") }}</span>
            </Btn>
          </BtnDropdown>
        </template>

        <FleetVehiclesFilterForm slot="filter" />

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
              />
            </template>
          </FilteredGrid>

          <FleetchartApp
            :items="records"
            namespace="fleet"
            :loading="loading"
            :download-name="`${fleet.slug}-fleetchart`"
          />
        </template>
      </FilteredList>
    </div>
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
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import FleetVehiclePanel from "@/frontend/components/Fleets/VehiclePanel/index.vue";
import FleetVehiclesFilterForm from "@/frontend/components/Fleets/FilterForm/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import ModelClassLabels from "@/frontend/components/Models/ClassLabels/index.vue";
import AddonsModal from "@/frontend/components/Vehicles/AddonsModal/index.vue";
import fleetVehiclesCollection from "@/frontend/api/collections/FleetVehicles";
import debounce from "lodash.debounce";
import { format } from "date-fns";
import { displayAlert } from "@/frontend/lib/Noty";

@Component<FleetShipsList>({
  components: {
    Btn,
    BtnDropdown,
    FilteredList,
    FilteredGrid,
    FleetVehiclePanel,
    ModelClassLabels,
    AddonsModal,
    FleetchartApp,
    FleetVehiclesFilterForm,
    ShareBtn,
  },
})
export default class FleetShipsList extends Vue {
  collection: FleetVehiclesCollection = fleetVehiclesCollection;

  fleetVehiclesChannel = null;

  @Prop({ required: true }) fleet: Fleet;

  @Prop({ required: true }) shareUrl: string;

  @Prop({ required: true }) metaTitle: string;

  @Getter("mobile") mobile;

  @Getter("grouped", { namespace: "fleet" }) grouped;

  @Getter("money", { namespace: "fleet" }) money;

  @Getter("detailsVisible", { namespace: "fleet" }) detailsVisible;

  @Getter("perPage", { namespace: "fleet" }) perPage;

  @Getter("fleetchartVisible", { namespace: "fleet" }) fleetchartVisible;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  @Action("toggleFleetchart", { namespace: "fleet" }) toggleFleetchart: any;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  @Action("toggleDetails", { namespace: "fleet" }) toggleDetails: any;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  @Action("toggleGrouped", { namespace: "fleet" }) toggleGrouped: any;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  @Action("toggleMoney", { namespace: "fleet" }) toggleMoney: any;

  get fleetStats() {
    return this.collection.stats;
  }

  get modelCounts() {
    return this.collection.modelCounts;
  }

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
      filters: this.$route.query.q,
      grouped: this.grouped,
      page: this.$route.query.page,
    };
  }

  @Watch("perPage")
  onPerPageChange() {
    this.fetch();
  }

  @Watch("grouped")
  onGroupedChange() {
    this.fetch();
  }

  @Watch("$route")
  onRouteChange() {
    this.fetchStats();
    this.fetchModelCounts();
  }

  @Watch("fleet")
  onFleetChange() {
    this.fetchStats();
    this.fetchModelCounts();
  }

  mounted() {
    this.fetchStats();
    this.fetchModelCounts();
    this.setupUpdates();
  }

  setupUpdates() {
    if (this.fleetVehiclesChannel) {
      this.fleetVehiclesChannel.unsubscribe();
    }

    this.fleetVehiclesChannel = this.$cable.consumer.subscriptions.create(
      {
        channel: "FleetVehiclesChannel",
      },
      {
        received: debounce(this.fetch, 500),
      },
    );
  }

  async fetch() {
    await this.collection.findAll(this.filters);
    await this.fetchStats();
  }

  async fetchStats() {
    await this.collection.findStats(this.filters);
  }

  async fetchModelCounts() {
    await this.collection.findModelCounts(this.filters);
  }

  async exportJson() {
    const exportedData = await this.collection.export(this.filters);

    // eslint-disable-next-line compat/compat
    if (!exportedData || !window.URL) {
      displayAlert({ text: this.$t("messages.hangarExport.failure") });
      return;
    }

    const link = document.createElement("a");

    // eslint-disable-next-line compat/compat
    link.href = window.URL.createObjectURL(new Blob([exportedData]));

    link.setAttribute(
      "download",
      `fleetyards-${this.fleet.slug}-vehicles-${format(
        new Date(),
        "yyyy-MM-dd",
      )}.json`,
    );

    document.body.appendChild(link);

    link.click();

    document.body.removeChild(link);
  }
}
</script>
