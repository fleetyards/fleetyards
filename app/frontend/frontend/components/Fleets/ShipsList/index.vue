<script lang="ts">
export default {
  name: "FleetShipsList",
};
</script>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import SortBar from "@/shared/components/base/Table/SortBar/index.vue";
import { useVehicleSortFields } from "@/frontend/composables/useVehicleSortFields";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import FleetVehiclePanel from "@/frontend/components/Fleets/VehiclePanel/index.vue";
import FleetVehiclesTable from "@/frontend/components/Fleets/VehiclesTable/index.vue";
import FleetVehiclesFilterForm from "@/frontend/components/Fleets/FilterForm/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import ModelClassLabels from "@/frontend/components/Models/ClassLabels/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { format } from "date-fns";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useFilters } from "@/shared/composables/useFilters";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useSubscription } from "@/shared/composables/useSubscription";
import { FleetVehiclesChannel } from "@/services/fyCable/channels/FleetVehiclesChannel";
import { useDebouncedRefresh } from "@/shared/composables/useDebouncedRefresh";
import { useMobile } from "@/shared/composables/useMobile";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { storeToRefs } from "pinia";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type FleetVehicleQuery,
  type Fleet,
  type FleetSquadron,
  type VehicleExport,
} from "@/services/fyApi";
import {
  fleetShipsQueryKey,
  useFleetShipsSource,
} from "@/frontend/composables/useFleetShipsSource";

type Props = {
  fleet: Fleet;
  // Narrows every query, the exports included, to one squadron's members. The
  // squadron endpoints subclass the fleet's and override only the scope, so
  // this list behaves identically either way rather than being a second,
  // thinner ship list that drifts.
  squadron?: FleetSquadron;
};

const props = withDefaults(defineProps<Props>(), {
  squadron: undefined,
});

const { t, toDollar, toUEC, toNumber } = useI18n();

const sortFields = useVehicleSortFields();

const { displayAlert } = useAppNotifications();

const comlink = useComlink();

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/DisplayOptionsModal/index.vue"),
  });
};

const mobile = useMobile();

const fleetStore = useFleetStore();

const { grouped, money, detailsVisible, gridView } = storeToRefs(fleetStore);

const fleetchartStore = useFleetchartStore();

const exportScope = computed(() =>
  props.squadron
    ? `${props.fleet.slug}-${props.squadron.slug}`
    : props.fleet.slug,
);

// The fleetchart's own page is the fleet's; a squadron has no public one to
// point at, so its chart is drawn but not offered for sharing.
const fleetchartShareUrl = computed(() => {
  if (props.squadron || !props.fleet?.publicFleet) {
    return undefined;
  }

  const host = `${window.location.protocol}//${window.location.host}`;

  return `${host}/fleets/${props.fleet.slug}/fleetchart`;
});

const listName = computed(() =>
  props.squadron ? "fleet-squadron-ships" : "fleet-ships",
);

const fleetchartNamespace = computed(() =>
  props.squadron ? "fleet-squadron" : "fleet",
);

const fleetchartVisible = computed(() => {
  return fleetchartStore.isVisible(fleetchartNamespace.value);
});

watch(
  () => grouped.value,
  () => refetch(),
);

watch(
  () => [props.fleet, props.squadron],
  () => refetch(),
);

const exportJson = async () => {
  try {
    const exportedData = await fetchExport(fleetVehiclesQueryParams.value);

    downloadExport(exportedData, "vehicles");
  } catch (error) {
    displayAlert({ text: t("messages.hangarExport.failure") });
    console.error(error);
  }
};

const exportHangarLink = async () => {
  try {
    const exportedData = await fetchHangarLinkExport(
      fleetVehiclesQueryParams.value,
    );

    downloadExport(exportedData, "hangar-link");
  } catch (error) {
    displayAlert({ text: t("messages.hangarExport.failure") });
    console.error(error);
  }
};

const downloadExport = (data: VehicleExport[] | undefined, suffix: string) => {
  if (!data || !window.URL) {
    displayAlert({ text: t("messages.hangarExport.failure") });
    return;
  }

  const link = document.createElement("a");

  link.href = window.URL.createObjectURL(
    new Blob([JSON.stringify(data, null, 2)], { type: "application/json" }),
  );

  link.setAttribute(
    "download",
    `fleetyards-${exportScope.value}-${suffix}-${format(
      new Date(),
      "yyyy-MM-dd",
    )}.json`,
  );

  document.body.appendChild(link);

  link.click();

  document.body.removeChild(link);
};

const route = useRoute();

const fleetSlug = computed(() => route.params.slug as string);

const squadronSlug = computed(() => props.squadron?.slug);

const { getQuery } = useFilters<FleetVehicleQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

// Order matters here, and it is not arbitrary: the queries read the params,
// the params read the page, and the page comes from `usePagination` -- which
// only wants the key. So the key is derived first, then the page, then the
// params, then the queries that consume them.
const fleetVehiclesQueryKey = fleetShipsQueryKey(fleetSlug, squadronSlug);

const { perPage, page, updatePerPage } = usePagination(fleetVehiclesQueryKey);

const fleetVehiclesQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: getQuery(),
    grouped: grouped.value,
  };
});

const {
  vehicles: fleetVehicles,
  stats: fleetStats,
  modelCounts,
  asyncStatus,
  refetch,
  fetchExport,
  fetchHangarLinkExport,
} = useFleetShipsSource(fleetSlug, squadronSlug, fleetVehiclesQueryParams);

const refresh = useDebouncedRefresh(refetch);

useSubscription({
  channel: FleetVehiclesChannel,
  received: refresh,
  // The channel replays nothing it broadcast while the socket was down, so
  // the fleet's ships is read again on the way back rather than waiting for whatever
  // changes next.
  connected: ({ reconnect }) => {
    if (reconnect) {
      refresh();
    }
  },
});
</script>

<template>
  <div class="row">
    <div class="col-12 col-lg-12">
      <div class="fleet-header">
        <div class="fleet-labels">
          <ModelClassLabels
            v-if="fleetStats"
            :label="t('labels.classifications')"
            :count-data="fleetStats.classifications"
            filter-key="classificationIn"
            exclude-filter-key="classificationNotIn"
          />
        </div>
      </div>

      <div v-if="fleetStats && fleetStats.metrics && !mobile" class="row">
        <div
          class="col-12 fleet-metrics metrics-block"
          @click="fleetStore.toggleMoney"
        >
          <div v-if="money" class="metrics-item">
            <div class="metrics-label">
              {{ t("labels.hangarMetrics.totalMoney") }}:
            </div>
            <div class="metrics-value">
              {{ toDollar(fleetStats.metrics.totalMoney) }}
            </div>
          </div>
          <div v-if="money" class="metrics-item">
            <div class="metrics-label">
              {{ t("labels.hangarMetrics.totalCredits") }}:
            </div>
            <div class="metrics-value">
              <!-- eslint-disable-next-line vue/no-v-html -->
              <span v-html="toUEC(fleetStats.metrics.totalCredits)" />
            </div>
          </div>
          <div class="metrics-item">
            <div class="metrics-label">
              {{ t("labels.hangarMetrics.total") }}:
            </div>
            <div class="metrics-value">
              {{ toNumber(fleetStats.total, "ships") }}
            </div>
          </div>
          <div class="metrics-item">
            <div class="metrics-label">
              {{ t("labels.hangarMetrics.totalMinCrew") }}:
            </div>
            <div class="metrics-value">
              {{ toNumber(fleetStats.metrics.totalMinCrew, "people") }}
            </div>
          </div>
          <div class="metrics-item">
            <div class="metrics-label">
              {{ t("labels.hangarMetrics.totalMaxCrew") }}:
            </div>
            <div class="metrics-value">
              {{ toNumber(fleetStats.metrics.totalMaxCrew, "people") }}
            </div>
          </div>
          <div class="metrics-item">
            <div class="metrics-label">
              {{ t("labels.hangarMetrics.totalCargo") }}:
            </div>
            <div class="metrics-value">
              {{ toNumber(fleetStats.metrics.totalCargo, "cargo") }}
            </div>
          </div>
        </div>
      </div>

      <FilteredList
        :name="listName"
        :records="fleetVehicles?.items || []"
        :async-status="asyncStatus"
        primary-key="id"
        :hide-loading="fleetchartVisible || !gridView"
        :hide-empty="!gridView"
      >
        <template #actions-right>
          <Btn
            :aria-label="t('actions.models.openTableConfiguration')"
            @click="openDisplayOptionsModal"
          >
            <i class="fa-duotone fa-sliders" />
          </Btn>
          <BtnDropdown>
            <Btn :aria-label="t('actions.export')" @click="exportJson">
              <i class="fa-light fa-download" />
              <span>{{ t("actions.export") }}</span>
            </Btn>

            <Btn
              :aria-label="t('actions.exportHangarLink')"
              @click="exportHangarLink"
            >
              <i class="fa-light fa-link" />
              <span>{{ t("actions.exportHangarLink") }}</span>
            </Btn>
          </BtnDropdown>
        </template>

        <template #filter>
          <FleetVehiclesFilterForm />
        </template>
        <template v-if="gridView" #skeleton="{ filterVisible }">
          <GridSkeleton
            :details="detailsVisible"
            :filter-visible="filterVisible"
          />
        </template>

        <template #sort>
          <!-- Grid view only: the table carries the same sorts on its headings. -->
          <SortBar
            v-if="gridView"
            :columns="sortFields"
            default-sort="name asc"
          />
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
              />
            </template>
          </Grid>

          <FleetVehiclesTable
            v-else
            :fleet-slug="fleet.slug"
            :loading="loading"
            :empty-visible="emptyVisible"
            :vehicles="fleetVehicles?.items || []"
            :model-counts="modelCounts"
          />

          <FleetchartApp
            :items="fleetVehicles?.items || []"
            :namespace="fleetchartNamespace"
            :share-url="fleetchartShareUrl"
            :share-title="fleet.name"
            :loading="loading"
            :download-name="`${exportScope}-fleetchart`"
          >
            <template #pagination>
              <Paginator
                :query-result-ref="fleetVehicles"
                :per-page="perPage"
                :size="BtnSizesEnum.SM"
                :update-per-page="updatePerPage"
              />
            </template>
          </FleetchartApp>
        </template>
        <template #pagination-top>
          <Paginator
            :query-result-ref="fleetVehicles"
            :per-page="perPage"
            :update-per-page="updatePerPage"
          />
        </template>

        <template #pagination-bottom>
          <Paginator
            :query-result-ref="fleetVehicles"
            :per-page="perPage"
            :update-per-page="updatePerPage"
          />
        </template>
      </FilteredList>
    </div>
  </div>
</template>
