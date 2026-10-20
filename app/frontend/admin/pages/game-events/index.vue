<script lang="ts">
export default {
  name: "AdminGameEventsPage",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import Paginator from "@/shared/components/Paginator/index.vue";
import GameEventActions from "@/admin/components/GameEvents/Actions/index.vue";
import {
  useGameEvents,
  type GameEvent,
  type GameEventSortEnum,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";
import { useGameEventFilters } from "@/admin/composables/useGameEventFilters";

const route = useRoute();

const sorts = computed((): GameEventSortEnum[] => {
  return route.query.s ? [route.query.s as GameEventSortEnum] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const { perPage, page, updatePerPage } = usePagination();

const { filters, isFilterSelected } = useGameEventFilters(async () => {
  await refetch();
});

const gameEventsQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    ...filters.value,
    sorts: sorts.value,
  },
}));

const {
  data: gameEvents,
  refetch,
  ...asyncStatus
} = useGameEvents(gameEventsQueryParams);

const { t, l } = useI18n();

const columns: BaseTableCol<GameEvent>[] = [
  { name: "title", label: t("labels.gameEvent.title"), sortable: true },
  { name: "category", label: t("labels.gameEvent.category"), mobile: false },
  { name: "startsAt", label: t("labels.gameEvent.startsAt"), sortable: true },
  { name: "endsAt", label: t("labels.gameEvent.endsAt"), mobile: false },
  { name: "published", label: t("labels.gameEvent.published") },
];
</script>

<template>
  <Heading hero mobile-hidden>
    {{ t("headlines.admin.gameEvents.index") }}
    <HeadingSmall v-if="gameEvents">
      {{
        t("headlines.pagination.count", {
          current: gameEvents?.items.length,
          total: gameEvents?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn
      class="navigation-header-pinned"
      :size="BtnSizesEnum.MD"
      :to="{ name: 'admin-game-event-create' }"
      :aria-label="t('actions.create')"
      mobile-icon-only
    >
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-game-events"
    :records="gameEvents?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
    :is-filter-selected="isFilterSelected"
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="gameEvents?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="startsAt desc"
        selectable
      >
        <template #col-title="{ record }">
          <router-link
            :to="{ name: 'admin-game-event-edit', params: { id: record.id } }"
          >
            {{ record.title }}
          </router-link>
        </template>
        <template #col-category="{ record }">
          {{ t(`labels.fleets.missions.categories.${record.category}`) }}
        </template>
        <template #col-startsAt="{ record }">
          {{ l(record.startsAt, "datetime.formats.short") }}
        </template>
        <template #col-endsAt="{ record }">
          <span v-if="record.endsAt">
            {{ l(record.endsAt, "datetime.formats.short") }}
          </span>
          <span v-else>—</span>
        </template>
        <template #col-published="{ record }">
          <i v-if="record.published" class="fa-duotone fa-circle-check" />
          <i v-else class="fa-duotone fa-circle-xmark" />
        </template>
        <template #actions="{ record }">
          <GameEventActions :game-event="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        :query-result-ref="gameEvents"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="gameEvents"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
