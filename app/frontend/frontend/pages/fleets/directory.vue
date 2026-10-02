<script lang="ts">
export default {
  name: "FleetDirectoryPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import FilterForm from "@/frontend/components/Fleets/Directory/FilterForm/index.vue";
import FleetDirectoryList from "@/frontend/components/Fleets/Directory/List/index.vue";
import FleetDirectoryCard from "@/frontend/components/Fleets/Directory/Card/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useFleetDirectoryStore } from "@/frontend/stores/fleetDirectory";
import { storeToRefs } from "pinia";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import { useFleetDirectorySortFields } from "@/frontend/composables/useFleetDirectorySortFields";
import { useI18n } from "@/shared/composables/useI18n";
import { usePagination } from "@/shared/composables/usePagination";
import { useFleetDirectoryFilters } from "@/frontend/composables/useFleetDirectoryFilters";
import {
  type FleetDirectoryEntry,
  useFleetDirectory as useFleetDirectoryQuery,
  getFleetDirectoryQueryKey,
} from "@/services/fyApi";

const { t } = useI18n();

const directoryQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const directoryQueryKey = computed(() =>
  getFleetDirectoryQueryKey(directoryQueryParams),
);

const { perPage, page, updatePerPage } = usePagination(directoryQueryKey);

const { isFilterSelected, getQuery } = useFleetDirectoryFilters(async () => {
  await refetch();
});

const {
  data: fleets,
  refetch,
  ...asyncStatus
} = useFleetDirectoryQuery(directoryQueryParams);

const sortFields = useFleetDirectorySortFields();

const comlink = useComlink();

const directoryStore = useFleetDirectoryStore();
const { gridView } = storeToRefs(directoryStore);

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/shared/components/DisplayOptionsModal/index.vue"),
    props: {
      gridView: gridView.value,
      testPrefix: "fleet-directory",
      updateCallback: (next: boolean) => {
        directoryStore.gridView = next;
      },
    },
  });
};
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.directory") }}</Heading>
  <p class="text-muted">{{ t("texts.fleets.directory") }}</p>

  <FilteredList
    name="fleet-directory"
    :records="fleets?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #actions-right>
      <Btn
        :size="BtnSizesEnum.SM"
        :aria-label="t('actions.models.openTableConfiguration')"
        data-test="fleet-directory-display-options"
        @click="openDisplayOptionsModal"
      >
        <i class="fa-duotone fa-sliders" />
      </Btn>
    </template>

    <template #filter>
      <FilterForm />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="fleets"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>

    <template #skeleton="{ count, filterVisible }">
      <GridSkeleton v-if="gridView" :filter-visible="filterVisible" />
      <RowsSkeleton v-else :count="count" icon meta trailing />
    </template>

    <template #sort>
      <ListToolbar :columns="sortFields" default-sort="memberCount desc" />
    </template>

    <template #default="{ records, emptyVisible: listEmpty, filterVisible }">
      <Grid
        v-if="gridView"
        :records="records as FleetDirectoryEntry[]"
        primary-key="id"
        :filter-visible="filterVisible"
      >
        <template #default="{ record }">
          <FleetDirectoryCard :fleet="record" />
        </template>
      </Grid>
      <FleetDirectoryList
        v-else
        :fleets="records as FleetDirectoryEntry[]"
        :empty-visible="listEmpty"
      />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="fleets"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
