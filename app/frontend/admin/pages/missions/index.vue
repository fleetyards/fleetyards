<script lang="ts">
export default {
  name: "AdminMissionsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import FilterForm from "@/admin/components/Missions/FilterForm/index.vue";
import {
  useGameMissions,
  getGameMissionsQueryKey,
  type GameMission,
  type GameMissionSortEnum,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionFilters } from "@/admin/composables/useMissionFilters";

const route = useRoute();

const sorts = computed((): GameMissionSortEnum[] => {
  return route.query.s ? [route.query.s as GameMissionSortEnum] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const missionsQueryKey = computed(() => {
  return getGameMissionsQueryKey(missionsQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(missionsQueryKey);

const { filters, isFilterSelected } = useMissionFilters(async () => {
  await refetch();
});

const missionsQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: {
      ...filters.value,
      sorts: sorts.value,
    },
  };
});

const {
  data: missions,
  refetch,
  ...asyncStatus
} = useGameMissions(missionsQueryParams);

const { t } = useI18n();

const columns: BaseTableCol<GameMission>[] = [
  { name: "name", label: t("labels.gameMission.name"), sortable: true },
  {
    name: "org",
    label: t("labels.gameMission.org"),
    mobile: false,
    sortable: true,
  },
  {
    name: "standing",
    label: t("labels.gameMission.standing"),
    mobile: false,
  },
  {
    name: "rewards",
    label: t("labels.gameMission.rewards"),
    mobile: false,
  },
  {
    name: "released",
    label: t("labels.admin.missions.columns.released"),
    alignment: "center",
    mobile: false,
  },
  {
    name: "generator",
    label: t("labels.admin.missions.columns.generator"),
    mobile: false,
  },
  {
    name: "build",
    label: t("labels.admin.missions.columns.build"),
    mobile: false,
  },
];

const rewardNames = (record: GameMission) =>
  (record.rewardKinds || [])
    .map((kind) => t(`labels.gameMission.rewardKinds.${kind}`))
    .join(", ");

const standing = (record: GameMission) => {
  if (!record.minStanding) return "";
  if (!record.maxStanding || record.maxStanding === record.minStanding) {
    return record.minStanding;
  }

  return `${record.minStanding} – ${record.maxStanding}`;
};

// A tick and a cross carry the whole answer in this column, and an icon has no
// accessible name -- so it is read out rather than only drawn.
const releasedStatus = (record: GameMission) =>
  record.released
    ? t("labels.filters.missions.released")
    : t("labels.gameMission.unreleased");
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.missions.index") }}
    <HeadingSmall v-if="missions">
      {{
        t("headlines.pagination.count", {
          current: missions?.items.length,
          total: missions?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    name="admin-missions"
    :records="missions?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="missions?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="name asc"
      >
        <template #col-name="{ record }">
          <router-link
            :to="{ name: 'admin-mission', params: { id: record.id } }"
          >
            <!-- The key where the game never named it: 74 rows have no name at
                 all, and this section is where they are looked at. -->
            {{ record.name || record.scKey }}
          </router-link>
        </template>
        <template #col-org="{ record }">
          <span v-if="record.org">{{ record.org.name }}</span>
          <span v-else class="mission-quiet">
            {{ t("labels.gameMission.offeredByUnknown") }}
          </span>
        </template>
        <template #col-standing="{ record }">
          {{ standing(record) }}
        </template>
        <template #col-rewards="{ record }">
          {{ rewardNames(record) }}
        </template>
        <template #col-released="{ record }">
          <i
            :class="
              record.released ? 'fa-duotone fa-check' : 'fa-duotone fa-times'
            "
            aria-hidden="true"
          />
          <span class="sr-only">{{ releasedStatus(record) }}</span>
        </template>
        <template #col-generator="{ record }">
          <span class="mission-quiet">{{ record.generatorKey }}</span>
        </template>
        <template #col-build="{ record }">
          <span :class="{ 'mission-quiet': record.retired }">
            {{ record.build?.version }}
          </span>
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        :query-result-ref="missions"
        :per-page="perPage"
        :update-per-page="updatePerPage"
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

<style lang="scss" scoped>
.mission-quiet {
  color: var(--color-text-dim);
}
</style>
