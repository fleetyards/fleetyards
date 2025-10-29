<template>
  <div>
    <FilteredList
      name="fleet-public-ships"
      :records="fleetVehicles?.items || []"
      :async-status="asyncStatus"
      primary-key="id"
      :hide-loading="fleetchartVisible"
    >
      <template #actions-right>
        <BtnDropdown :size="BtnSizesEnum.SMALL">
          <template v-if="mobile">
            <Btn
              :size="BtnSizesEnum.SMALL"
              data-test="fleetchart-link"
              @click="toggleFleetchart"
            >
              <i class="fad fa-starship" />
              <span>{{ t("labels.fleetchart") }}</span>
            </Btn>

            <hr />
          </template>
          <Btn
            :active="detailsVisible"
            :aria-label="toggleDetailsTooltip"
            :size="BtnSizesEnum.SMALL"
            @click="fleetStore.toggleDetails"
          >
            <i class="fad fa-info-square" />
            <span>{{ toggleDetailsTooltip }}</span>
          </Btn>

          <Btn :size="BtnSizesEnum.SMALL" @click="fleetStore.toggleGrouped">
            <template v-if="grouped">
              <i class="fas fa-object-intersect" />
              <span>{{ t("actions.ungrouped") }}</span>
            </template>
            <template v-else>
              <i class="fas fa-object-union" />
              <span>{{ t("actions.groupedByModel") }}</span>
            </template>
          </Btn>
        </BtnDropdown>
      </template>

      <template #filter>
        <PublicFleetVehiclesFilterForm />
      </template>
      <template #default="{ records, loading, filterVisible }">
        <Grid
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

        <FleetchartApp
          :items="fleetVehicles?.items || []"
          namespace="publicFleet"
          :loading="loading"
          :download-name="`${fleet.slug}-fleetchart`"
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

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import FleetVehiclePanel from "@/frontend/components/Fleets/VehiclePanel/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import PublicFleetVehiclesFilterForm from "@/frontend/components/Fleets/PublicFilterForm/index.vue";
import type { Fleet, FleetVehicleQuery } from "@/services/fyApi";
import { useMobile } from "@/shared/composables/useMobile";
import { usePublicFleetStore } from "@/frontend/stores/publicFleet";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { storeToRefs } from "pinia";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import { usePagination } from "@/shared/composables/usePagination";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  usePublicFleetVehiclesQueryOptions,
  usePublicFleetStatsModelCounts as usePublicFleetStatsModelCountsQuery,
  usePublicFleetVehicles as usePublicFleetVehiclesQuery,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

const mobile = useMobile();

const fleetStore = usePublicFleetStore();

const { grouped, detailsVisible } = storeToRefs(fleetStore);

const fleetchartStore = useFleetchartStore();

const fleetchartVisible = computed(() => {
  return fleetchartStore.isVisible("publicFleet");
});

const toggleFleetchart = () => {
  fleetchartStore.toggleFleetchart("publicFleet");
};

const toggleDetailsTooltip = computed(() => {
  if (detailsVisible.value) {
    return t("actions.hideDetails");
  }

  return t("actions.showDetails");
});

watch(
  () => grouped.value,
  () => refetch,
);

watch(
  () => props.fleet,
  () => refetch,
);

const vehiclesQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: filters.value,
  };
});

const { data: modelCounts, refetch: refetchModelCounts } =
  usePublicFleetStatsModelCountsQuery(props.fleet.slug, vehiclesQueryParams);

const refetch = () => {
  refetchVehicles();
  refetchModelCounts();
};

const vehiclesQueryKey = computed(() => {
  return usePublicFleetVehiclesQueryOptions(
    props.fleet.slug,
    vehiclesQueryParams,
  ).queryKey;
});

const {
  data: fleetVehicles,
  refetch: refetchVehicles,
  ...asyncStatus
} = usePublicFleetVehiclesQuery(props.fleet.slug, vehiclesQueryParams);

const { filters } = useFilters<FleetVehicleQuery>({
  updateCallback: refetch,
});

const { perPage, page, updatePerPage } = usePagination(vehiclesQueryKey);
</script>

<script lang="ts">
export default {
  name: "FleetPublicShipsList",
};
</script>
