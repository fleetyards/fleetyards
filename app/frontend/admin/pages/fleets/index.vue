<script lang="ts">
export default {
  name: "AdminFleetsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import FilterForm from "@/admin/components/Fleets/FilterForm/index.vue";
import {
  useFleets,
  getFleetsQueryKey,
  type Fleet,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import type { FleetQuery } from "@/services/fyAdminApi";
import FleetActions from "@/admin/components/Fleets/Actions/index.vue";

const route = useRoute();

const sorts = computed(() => {
  return route.query.s ? [route.query.s as string] : [];
});

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

const fleetsQueryKey = computed(() => {
  return getFleetsQueryKey(fleetsQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(fleetsQueryKey);

const { filters, isFilterSelected } = useFilters<FleetQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const fleetsQueryParams = computed(() => {
  return {
    page: page.value,
    q: filters.value,
    s: sorts.value,
  };
});

const { data: fleets, refetch, ...asyncStatus } = useFleets(fleetsQueryParams);

const columns: BaseTableCol<Fleet>[] = [
  {
    name: "logo",
    label: "",
    width: "120px",
    alignment: "center",
  },
  {
    name: "name",
    label: "Name",
    sortable: true,
  },
  {
    name: "fid",
    label: "FID",
    sortable: true,
  },
  {
    name: "publicFleet",
    label: "Public",
    mobile: false,
  },
  {
    name: "createdAt",
    label: "Created At",
    mobile: false,
    sortable: true,
  },
  {
    name: "updatedAt",
    label: "Updated At",
    mobile: false,
    sortable: true,
  },
];

const { t, l } = useI18n();
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.fleets.index") }}
    <HeadingSmall v-if="fleets">
      {{
        t("headlines.pagination.count", {
          current: fleets?.items.length,
          total: fleets?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    name="admin-fleets"
    :records="fleets?.items || []"
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
        :records="fleets?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="name asc"
        selectable
      >
        <template #col-logo="{ record }">
          <LazyImage
            v-if="record.logo"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.logo?.smallUrl"
            alt="Fleet logo"
            transparent
          />
        </template>
        <template #col-name="{ record }">
          {{ record.name }}
        </template>
        <template #col-fid="{ record }">
          {{ record.fid }}
        </template>
        <template #col-publicFleet="{ record }">
          <i v-if="record.publicFleet" class="fa-duotone fa-check" />
          <i v-else class="fa-duotone fa-times" />
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #col-updatedAt="{ record }">
          {{ l(record.updatedAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <FleetActions :fleet="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="fleets"
        :query-result-ref="fleets"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="fleets"
        :query-result-ref="fleets"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
