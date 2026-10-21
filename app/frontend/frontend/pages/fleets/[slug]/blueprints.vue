<script lang="ts">
export default {
  name: "FleetBlueprintsPage",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import FilterForm from "@/frontend/components/Blueprints/FilterForm/index.vue";
import FleetBlueprintsList from "@/frontend/components/Fleets/BlueprintsList/index.vue";
import { useBlueprintSortFields } from "@/frontend/composables/useBlueprintSortFields";
import { useBlueprintFilters } from "@/frontend/composables/useBlueprintFilters";
import { useBlueprintsTab } from "@/frontend/composables/useBlueprintsTab";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { usePagination } from "@/shared/composables/usePagination";
import {
  useFleetBlueprints as useFleetBlueprintsQuery,
  useFleetWantedBlueprints as useFleetWantedBlueprintsQuery,
  type Fleet,
  type FleetBlueprint,
  type FleetWantedBlueprint,
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

const { perPage, page, updatePerPage } = usePagination();

const { activeTab } = useBlueprintsTab();

const { isFilterSelected, getQuery } = useBlueprintFilters(async () => {
  await activeQuery.value.refetch();
});

// One query per list, each asked only while its tab is open: the two are
// different endpoints, and a closed tab has nothing to show.
const ownedQuery = useFleetBlueprintsQuery(fleetSlug, queryParams, {
  query: { enabled: computed(() => activeTab.value === "owned") },
});

const wantedQuery = useFleetWantedBlueprintsQuery(fleetSlug, queryParams, {
  query: { enabled: computed(() => activeTab.value === "wanted") },
});

const activeQuery = computed(() =>
  activeTab.value === "wanted" ? wantedQuery : ownedQuery,
);

const blueprints = computed(() => activeQuery.value.data.value);

const records = computed<(FleetBlueprint | FleetWantedBlueprint)[]>(
  () => blueprints.value?.items || [],
);

const asyncStatus = computed(() => {
  const { data: _data, refetch: _refetch, ...status } = activeQuery.value;

  return status;
});

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
    :records="records"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>

    <template #actions-left>
      <BtnGroup segmented>
        <Btn
          :active="activeTab === 'owned'"
          mobile-icon-only
          data-test="fleet-blueprints-tab-owned"
          @click="activeTab = 'owned'"
        >
          <i class="fa-duotone fa-bookmark" />
          {{ t("labels.hangarBlueprints.owned") }}
        </Btn>
        <Btn
          :active="activeTab === 'wanted'"
          mobile-icon-only
          data-test="fleet-blueprints-tab-wanted"
          @click="activeTab = 'wanted'"
        >
          <i class="fa-duotone fa-wand-sparkles" />
          {{ t("labels.hangarBlueprints.wanted") }}
        </Btn>
      </BtnGroup>
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="blueprints"
        :per-page="perPage"
        :update-per-page="updatePerPage"
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
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
