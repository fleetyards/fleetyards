<script lang="ts">
export default {
  name: "FleetShipsList",
};
</script>

<script lang="ts" setup>
import type { Subscription } from "@rails/actioncable";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import FleetVehiclePanel from "@/frontend/components/Fleets/VehiclePanel/index.vue";
import FleetVehiclesTable from "@/frontend/components/Fleets/VehiclesTable/index.vue";
import FleetVehiclesFilterForm from "@/frontend/components/Fleets/FilterForm/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import ModelClassLabels from "@/frontend/components/Models/ClassLabels/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import debounce from "lodash.debounce";
import { format } from "date-fns";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useFilters } from "@/shared/composables/useFilters";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useCable } from "@/shared/composables/useCable";
import { useMobile } from "@/shared/composables/useMobile";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { storeToRefs } from "pinia";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  useFleetModelCounts as useFleetModelCountsQuery,
  useFleetVehiclesStats as useFleetVehiclesStatsQuery,
  fleetVehiclesExport as fetchFleetVehiclesExport,
  useFleetVehicles as useFleetVehiclesQuery,
  getFleetVehiclesQueryKey,
  type FleetVehicleQuery,
  type Fleet,
  type VehicleExport,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  shareUrl: string;
  shareTitle: string;
};

const props = defineProps<Props>();

const { t, toDollar, toUEC, toNumber } = useI18n();

const { displayAlert } = useAppNotifications();

const comlink = useComlink();

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/DisplayOptionsModal/index.vue"),
  });
};

const fleetVehiclesChannel = ref<Subscription>();

const mobile = useMobile();

const fleetStore = useFleetStore();

const { grouped, money, detailsVisible, gridView } = storeToRefs(fleetStore);

const fleetchartStore = useFleetchartStore();

const fleetchartVisible = computed(() => {
  return fleetchartStore.isVisible("fleet");
});

const toggleFleetchart = () => {
  fleetchartStore.toggleFleetchart("fleet");
};

watch(
  () => grouped.value,
  () => refetch(),
);

watch(
  () => props.fleet,
  () => refetch(),
);

onMounted(() => {
  setupUpdates();
});

const { consumer } = useCable();

const setupUpdates = () => {
  if (fleetVehiclesChannel.value) {
    fleetVehiclesChannel.value.unsubscribe();
  }

  if (!consumer) {
    return;
  }

  fleetVehiclesChannel.value = consumer.subscriptions.create(
    {
      channel: "FleetVehiclesChannel",
    },
    {
      received: () => debounce(refetch, 500),
    },
  );
};

const exportJson = async () => {
  try {
    const exportedData = await fetchFleetVehiclesExport(
      fleetSlug,
      fleetVehiclesQueryParams,
    );

    downloadExport(exportedData);
  } catch (error) {
    displayAlert({ text: t("messages.hangarExport.failure") });
    console.error(error);
  }
};

const downloadExport = (data?: VehicleExport[]) => {
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
    `fleetyards-${props.fleet.slug}-vehicles-${format(
      new Date(),
      "yyyy-MM-dd",
    )}.json`,
  );

  document.body.appendChild(link);

  link.click();

  document.body.removeChild(link);
};

const route = useRoute();

const fleetVehiclesQueryKey = computed(() => {
  return getFleetVehiclesQueryKey(
    fleetSlug.value,
    fleetVehiclesQueryParams.value,
  );
});

const { getQuery } = useFilters<FleetVehicleQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const { perPage, page, updatePerPage } = usePagination(fleetVehiclesQueryKey);

const fleetVehiclesQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: getQuery(),
    grouped: grouped.value,
  };
});

const fleetSlug = computed(() => route.params.slug as string);

const { data: fleetStats, refetch: refetchFleetStats } =
  useFleetVehiclesStatsQuery(fleetSlug);

const { data: modelCounts, refetch: refetchModelCounts } =
  useFleetModelCountsQuery(fleetSlug, fleetVehiclesQueryParams);

const refetch = async () => {
  await refetchVehicles();
  await refetchModelCounts();
  await refetchFleetStats();
};

const {
  data: fleetVehicles,
  refetch: refetchVehicles,
  ...asyncStatus
} = useFleetVehiclesQuery(fleetSlug, fleetVehiclesQueryParams);
</script>

<template>
  <div class="row">
    <div class="col-12 col-lg-12">
      <div class="fleet-header">
        <div class="fleet-labels">
          <ModelClassLabels
            v-if="fleetStats"
            :label="t('labels.fleet.classes')"
            :count-data="fleetStats.classifications"
            filter-key="classificationIn"
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
        name="fleet-ships"
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
          <BtnDropdown :size="BtnSizesEnum.SMALL">
            <template v-if="mobile">
              <Btn
                :size="BtnSizesEnum.SMALL"
                data-test="fleetchart-link"
                @click="toggleFleetchart"
              >
                <i class="fa-duotone fa-starship" />
                <span>{{ t("labels.fleetchart") }}</span>
              </Btn>

              <ShareBtn
                v-if="fleet.publicFleet"
                :url="shareUrl"
                :title="shareTitle"
                :size="BtnSizesEnum.SMALL"
              />

              <hr />
            </template>
            <Btn
              :size="BtnSizesEnum.SMALL"
              :aria-label="t('actions.export')"
              @click="exportJson"
            >
              <i class="fa-light fa-download" />
              <span>{{ t("actions.export") }}</span>
            </Btn>
          </BtnDropdown>
        </template>

        <template #filter>
          <FleetVehiclesFilterForm />
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
            namespace="fleet"
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
  </div>
</template>
