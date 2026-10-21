<script lang="ts">
export default {
  name: "HangarBlueprintsPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import BlueprintsTabs from "@/frontend/components/Blueprints/Tabs/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import RowsSkeleton from "@/shared/components/RowsSkeleton/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import BlueprintsList from "@/frontend/components/Blueprints/List/index.vue";
import FilterForm from "@/frontend/components/Blueprints/FilterForm/index.vue";
import MissionFilterForm from "@/frontend/components/Missions/FilterForm/index.vue";
import WantedMissionsList from "@/frontend/components/Blueprints/WantedMissions/index.vue";
import { useBlueprintSortFields } from "@/frontend/composables/useBlueprintSortFields";
import { useBlueprintFilters } from "@/frontend/composables/useBlueprintFilters";
import { useMissionSortFields } from "@/frontend/composables/useMissionSortFields";
import { useMissionFilters } from "@/frontend/composables/useMissionFilters";
import { useBlueprintsTab } from "@/frontend/composables/useBlueprintsTab";
import { useMissionShip } from "@/frontend/composables/useMissionShip";
import { useI18n } from "@/shared/composables/useI18n";
import { usePagination } from "@/shared/composables/usePagination";
import {
  useBlueprints as useBlueprintsQuery,
  useHangarBlueprintMissions as useHangarBlueprintMissionsQuery,
} from "@/services/fyApi";

const { t } = useI18n();

const TABS = ["owned", "wanted", "missions"] as const;

const { activeTab } = useBlueprintsTab(TABS);

const showMissions = computed(() => activeTab.value === "missions");

const { perPage, page, updatePerPage } = usePagination();

const { isFilterSelected, getQuery } = useBlueprintFilters(async () => {
  if (!showMissions.value) await blueprintsQuery.refetch();
});

const { isFilterSelected: isMissionFilterSelected, getQuery: getMissionQuery } =
  useMissionFilters(async () => {
    if (showMissions.value) await missionsQuery.refetch();
  });

// The tab decides which marker is asked for, so the form's own owned filter
// is not offered here and anything left of it in the URL is dropped.
const blueprintsParams = computed(() => {
  const { owned: _owned, wanted: _wanted, ...query } = getQuery();

  return {
    page: page.value,
    perPage: perPage.value,
    q: {
      ...query,
      // Everything held or wanted, not only the build we are on: a patch
      // dropping a recipe does not take it out of anybody's hands.
      currentVersion: false,
      ...(activeTab.value === "wanted" ? { wanted: true } : { owned: true }),
    },
  };
});

const missionsParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getMissionQuery(),
}));

// One query per list, each asked only while its tab is open.
const blueprintsQuery = useBlueprintsQuery(blueprintsParams, {
  query: { enabled: computed(() => !showMissions.value) },
});

const missionsQuery = useHangarBlueprintMissionsQuery(missionsParams, {
  query: { enabled: showMissions },
});

const statusOf = (query: typeof blueprintsQuery | typeof missionsQuery) => {
  const { data: _data, refetch: _refetch, ...status } = query;

  return status;
};

const blueprints = computed(() => blueprintsQuery.data.value);
const missions = computed(() => missionsQuery.data.value);

const shown = computed(() =>
  showMissions.value ? missions.value : blueprints.value,
);

// The pilot's ship, from the mission filter form: it marks rows rather than
// narrowing them.
const { ship } = useMissionShip();

const sortFields = useBlueprintSortFields();
const missionSortFields = useMissionSortFields();
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'hangar' }, label: t('nav.hangar.index') }]"
  />

  <Heading hero>
    {{ t("headlines.hangar.blueprints") }}
    <HeadingSmall data-test="hangar-blueprints-count">
      <template v-if="shown">
        {{
          t("headlines.pagination.count", {
            current: shown.items.length,
            total: shown.meta.pagination?.totalCount,
          })
        }}
      </template>
      <template v-else>&nbsp;</template>
    </HeadingSmall>
  </Heading>

  <FilteredList
    v-if="!showMissions"
    name="hangar-blueprints"
    :records="blueprints?.items || []"
    :async-status="statusOf(blueprintsQuery)"
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm hide-owned />
    </template>

    <template #actions-left>
      <BlueprintsTabs :tabs="TABS" />
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
      <BlueprintsList :blueprints="records" :empty-visible="listEmpty" />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="blueprints"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>

  <!-- Generated from the wanted blueprints: every mission whose reward pools
       hold one, with the mission catalogue's own filters. -->
  <FilteredList
    v-else
    name="hangar-blueprint-missions"
    :records="missions?.items || []"
    :async-status="statusOf(missionsQuery)"
    :is-filter-selected="isMissionFilterSelected"
    :view-keys="['ship']"
  >
    <template #filter>
      <MissionFilterForm />
    </template>

    <template #actions-left>
      <BlueprintsTabs :tabs="TABS" />
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="missions"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #skeleton="{ count }">
      <RowsSkeleton :count="count" meta trailing />
    </template>

    <template #sort>
      <ListToolbar :columns="missionSortFields" default-sort="name asc" />
    </template>

    <template #default="{ records, emptyVisible: listEmpty }">
      <WantedMissionsList
        :missions="records"
        :empty-visible="listEmpty"
        :ship="ship"
      />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="missions"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
