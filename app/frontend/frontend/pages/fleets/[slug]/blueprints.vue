<script lang="ts">
export default {
  name: "FleetBlueprintsPage",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import FilterForm from "@/frontend/components/Blueprints/FilterForm/index.vue";
import FleetBlueprintsList from "@/frontend/components/Fleets/BlueprintsList/index.vue";
import { useBlueprintSortFields } from "@/frontend/composables/useBlueprintSortFields";
import { useBlueprintFilters } from "@/frontend/composables/useBlueprintFilters";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { usePagination } from "@/shared/composables/usePagination";
import {
  useFleetBlueprints as useFleetBlueprintsQuery,
  getFleetBlueprintsQueryKey,
  type Fleet,
  type FleetMember,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership?: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { updateMetaInfo } = useMetaInfo();

const fleetSlug = computed(() => props.fleet.slug);

const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery(),
}));

const queryKey = computed(() =>
  getFleetBlueprintsQueryKey(fleetSlug, queryParams),
);

const { perPage, page, updatePerPage } = usePagination(queryKey);

const { isFilterSelected, getQuery } = useBlueprintFilters(async () => {
  await refetch();
});

const {
  data: blueprints,
  refetch,
  ...asyncStatus
} = useFleetBlueprintsQuery(fleetSlug, queryParams);

// Beside the list rather than inside it, for the reason the catalogue puts it
// there: `FilteredList` renders its results slot only once the first page has
// arrived, so a sort line inside is hidden exactly while a reader is waiting.
const sortFields = useBlueprintSortFields();

watch(
  () => props.fleet,
  (fleet) => {
    if (!fleet) return;

    updateMetaInfo({
      title: t("title.fleets.blueprints", { fleet: fleet.name }),
    });
  },
  { immediate: true },
);
</script>

<template>
  <div class="row">
    <div class="col-12">
      <h1 class="heading">
        <Avatar
          v-if="fleet.logo"
          :avatar="fleet.logo.smallUrl"
          :transparent="!!fleet.logo"
          icon="fa-duotone fa-image"
        />
        {{ fleet.name }} ({{ fleet.fid }})
      </h1>
    </div>
  </div>

  <FilteredList
    name="blueprints"
    :records="blueprints?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="blueprints"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>

    <template #skeleton="{ count }">
      <RowsSkeleton :count="count" meta trailing />
    </template>

    <template #sort>
      <ListToolbar :columns="sortFields" default-sort="name asc" />
    </template>

    <template #default="{ records, emptyVisible: listEmpty }">
      <FleetBlueprintsList :blueprints="records" :empty-visible="listEmpty" />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="blueprints"
        :per-page="perPage"
        @update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
