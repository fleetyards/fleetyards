<script lang="ts">
export default {
  name: "AdminRafflesPage",
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
import RaffleActions from "@/admin/components/Raffles/Actions/index.vue";
import {
  useRaffles,
  type Raffle,
  type RaffleSortEnum,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";

const route = useRoute();

const sorts = computed((): RaffleSortEnum[] => {
  return route.query.s ? [route.query.s as RaffleSortEnum] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const { perPage, page, updatePerPage } = usePagination();

const rafflesQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    sorts: sorts.value,
  },
}));

const {
  data: raffles,
  refetch,
  ...asyncStatus
} = useRaffles(rafflesQueryParams);

const { t, l } = useI18n();

const columns: BaseTableCol<Raffle>[] = [
  { name: "title", label: t("labels.raffle.title"), sortable: true },
  { name: "status", label: t("labels.raffle.status") },
  { name: "endsAt", label: t("labels.raffle.endsAt"), sortable: true },
  {
    name: "entriesCount",
    label: t("labels.raffle.entriesCount"),
    mobile: false,
  },
  { name: "codeSet", label: t("labels.raffle.code"), mobile: false },
];
</script>

<template>
  <Heading hero mobile-hidden>
    {{ t("headlines.admin.raffles.index") }}
    <HeadingSmall v-if="raffles">
      {{
        t("headlines.pagination.count", {
          current: raffles?.items.length,
          total: raffles?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn
      class="navigation-header-pinned"
      :size="BtnSizesEnum.MD"
      :to="{ name: 'admin-raffle-create' }"
      :aria-label="t('actions.create')"
      mobile-icon-only
    >
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-raffles"
    :records="raffles?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="raffles?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="endsAt desc"
      >
        <template #col-title="{ record }">
          <router-link
            :to="{ name: 'admin-raffle-entries', params: { id: record.id } }"
          >
            {{ record.title }}
          </router-link>
        </template>
        <template #col-status="{ record }">
          {{ t(`labels.raffle.statuses.${record.status}`) }}
        </template>
        <template #col-endsAt="{ record }">
          {{ l(record.endsAt, "datetime.formats.short") }}
        </template>
        <template #col-codeSet="{ record }">
          <i v-if="record.codeSet" class="fa-duotone fa-circle-check" />
          <i v-else class="fa-duotone fa-circle-xmark" />
        </template>
        <template #actions="{ record }">
          <RaffleActions :raffle="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        :query-result-ref="raffles"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="raffles"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
