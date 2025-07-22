<script lang="ts">
export default {
  name: "AdminManufacturersPage",
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
import ManufacturerActions from "@/admin/components/Manufacturers/Actions/index.vue";
import FilterForm from "@/admin/components/Manufacturers/FilterForm/index.vue";
import {
  useManufacturers,
  useManufacturersQueryOptions,
  type Manufacturer,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useManufacturerFilters } from "@/admin/composables/useManufacturerFilters";
import { CustomQueryOptions } from "@/services/customQueryOptions";

const route = useRoute();

const sorts = computed(() => {
  return route.query.s ? [route.query.s as string] : [];
});

watch(
  () => sorts.value,
  () => {
    refetch();
  },
);

const manufacturersQueryKey = computed(() => {
  return (useManufacturersQueryOptions() as CustomQueryOptions).queryKey;
});

const { perPage, page, updatePerPage } = usePagination(manufacturersQueryKey);

const { filters, isFilterSelected } = useManufacturerFilters(() => refetch());

const manufacturersQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: filters.value,
    s: sorts.value,
  };
});

const {
  data: manufacturers,
  refetch,
  ...asyncStatus
} = useManufacturers(manufacturersQueryParams);

const columns: BaseTableCol<Manufacturer>[] = [
  {
    name: "logo",
    label: "",
    centered: true,
  },
  {
    name: "name",
    label: "Name",
    sortable: true,
  },
  {
    name: "createdAt",
    label: "created at?",
    mobile: false,
    sortable: true,
  },
  {
    name: "updatedAt",
    label: "updated at?",
    mobile: false,
    sortable: true,
  },
];

const { t, l } = useI18n();
</script>

<template>
  <Heading>
    {{ t("headlines.admin.manufacturers.index") }}
    <HeadingSmall v-if="manufacturers">
      {{
        t("headlines.pagination.count", {
          current: manufacturers?.items.length,
          total: manufacturers?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn :to="{ name: 'admin-manufacturer-create' }">
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-manufacturers"
    :records="manufacturers?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, emptyVisible }">
      <BaseTable
        :records="manufacturers?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading"
        :empty-visible="emptyVisible"
        default-sort="name asc"
        selectable
      >
        <template #col-logo="{ record }">
          <LazyImage
            v-if="record.logo"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.logo"
            alt="Manufacturer logo"
            shadow
          />
        </template>
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-manufacturer-edit',
              params: {
                id: record.id,
              },
            }"
          >
            {{ record.code }} {{ record.name }}
          </router-link>
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #col-updatedAt="{ record }">
          {{ l(record.updatedAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <ManufacturerActions :manufacturer="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="manufacturers"
        :query-result-ref="manufacturers"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="manufacturers"
        :query-result-ref="manufacturers"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
