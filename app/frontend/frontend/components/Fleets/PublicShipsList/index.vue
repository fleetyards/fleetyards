<script lang="ts">
export default {
  name: "FleetPublicShipsList",
};
</script>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FleetVehiclePanel from "@/frontend/components/Fleets/VehiclePanel/index.vue";
import FleetVehiclesTable from "@/frontend/components/Fleets/VehiclesTable/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import PublicFleetVehiclesFilterForm from "@/frontend/components/Fleets/PublicFilterForm/index.vue";
import type { Fleet, FleetVehicleQuery } from "@/services/fyApi";
import { useMobile } from "@/shared/composables/useMobile";
import { usePublicFleetStore } from "@/frontend/stores/publicFleet";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { storeToRefs } from "pinia";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useFilters } from "@/shared/composables/useFilters";
import { usePagination } from "@/shared/composables/usePagination";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  usePublicFleetStatsModelCounts as usePublicFleetStatsModelCountsQuery,
  usePublicFleetVehicles as usePublicFleetVehiclesQuery,
  getPublicFleetVehiclesQueryKey,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

const mobile = useMobile();

const fleetStore = usePublicFleetStore();
const displayStore = useFleetStore();

const comlink = useComlink();

const { detailsVisible } = storeToRefs(fleetStore);
const { grouped, gridView } = storeToRefs(displayStore);

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/DisplayOptionsModal/index.vue"),
  });
};

const fleetchartStore = useFleetchartStore();

const fleetchartVisible = computed(() => {
  return fleetchartStore.isVisible("publicFleet");
});

const toggleFleetchart = () => {
  fleetchartStore.toggleFleetchart("publicFleet");
};

watch(
  () => grouped.value,
  () => refetch(),
);

watch(
  () => props.fleet,
  () => refetch(),
);

const vehiclesQueryKey = computed(() => {
  return getPublicFleetVehiclesQueryKey(
    props.fleet.slug,
    vehiclesQueryParams.value,
  );
});

const { filters } = useFilters<FleetVehicleQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const { perPage, page, updatePerPage } = usePagination(vehiclesQueryKey);

const vehiclesQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: filters.value,
    grouped: grouped.value,
  };
});

const { data: modelCounts, refetch: refetchModelCounts } =
  usePublicFleetStatsModelCountsQuery(props.fleet.slug, vehiclesQueryParams);

const {
  data: fleetVehicles,
  refetch: refetchVehicles,
  ...asyncStatus
} = usePublicFleetVehiclesQuery(props.fleet.slug, vehiclesQueryParams);

const refetch = async () => {
  await refetchVehicles();
  await refetchModelCounts();
};
</script>

<template>
  <div>
    <FilteredList
      name="fleet-public-ships"
      :records="fleetVehicles?.items || []"
      :async-status="asyncStatus"
      primary-key="id"
      :hide-loading="fleetchartVisible || !gridView"
      :hide-empty="!gridView"
    >
      <template #actions-right>
        <Btn
          :aria-label="t('actions.models.openTableConfiguration')"
          :size="BtnSizesEnum.SMALL"
          @click="openDisplayOptionsModal"
        >
          <i class="fa-duotone fa-sliders" />
        </Btn>
        <Btn
          v-if="mobile"
          :size="BtnSizesEnum.SMALL"
          data-test="fleetchart-link"
          @click="toggleFleetchart"
        >
          <i class="fa-duotone fa-starship" />
        </Btn>
      </template>

      <template #filter>
        <PublicFleetVehiclesFilterForm />
      </template>
      <template #default="{ records, loading, filterVisible, emptyVisible }">
        <Grid
          v-if="gridView"
          :records="records"
          :filter-visible="filterVisible"
          primary-key="id"
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
        </Grid>

        <FleetVehiclesTable
          v-else
          :fleet-slug="fleet.slug"
          :loading="loading"
          :empty-visible="emptyVisible"
          :vehicles="fleetVehicles?.items || []"
        />

        <FleetchartApp
          :items="fleetVehicles?.items || []"
          namespace="publicFleet"
          :loading="loading"
          :download-name="`${fleet.slug}-fleetchart`"
        />
      </template>
      <template #pagination-top>
        <Paginator
          v-if="fleetVehicles"
          :query-result-ref="fleetVehicles"
          :per-page="perPage"
          :update-per-page="updatePerPage"
        />
      </template>

      <template #pagination-bottom>
        <Paginator
          v-if="fleetVehicles"
          :query-result-ref="fleetVehicles"
          :per-page="perPage"
          :update-per-page="updatePerPage"
        />
      </template>
    </FilteredList>
  </div>
</template>
