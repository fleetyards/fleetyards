<script lang="ts">
export default {
  name: "AdminComponentsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import FilterForm from "@/admin/components/Components/FilterForm/index.vue";
import {
  useComponents,
  getComponentsQueryKey,
  type Component,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComponentFilters } from "@/admin/composables/useComponentFilters";

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

const componentsQueryKey = computed(() => {
  return getComponentsQueryKey(componentsQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(componentsQueryKey);

const { filters, isFilterSelected } = useComponentFilters(async () => {
  await refetch();
});

const componentsQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: filters.value,
    s: sorts.value,
  };
});

const {
  data: components,
  refetch,
  ...asyncStatus
} = useComponents(componentsQueryParams);

const columns: BaseTableCol<Component>[] = [
  {
    name: "name",
    label: "Name",
    sortable: true,
  },
  {
    name: "type",
    label: "Type",
    sortable: true,
    mobile: false,
  },
  {
    name: "size",
    label: "Size",
    mobile: false,
  },
  {
    name: "class",
    label: "Class",
    mobile: false,
  },
  {
    name: "itemClass",
    label: "Item Class",
    mobile: false,
  },
  {
    name: "manufacturer",
    label: "Manufacturer",
    mobile: false,
  },
  {
    name: "hidden",
    label: "Hidden",
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
  <Heading>
    {{ t("headlines.admin.components.index") }}
    <HeadingSmall v-if="components">
      {{
        t("headlines.pagination.count", {
          current: components?.items.length,
          total: components?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn :to="{ name: 'admin-component-create' }">
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-components"
    :records="components?.items || []"
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
        :records="components?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading"
        :empty-visible="emptyVisible"
        default-sort="name asc"
        selectable
      >
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-component-edit',
              params: {
                id: record.id,
              },
            }"
          >
            {{ record.name }}
          </router-link>
        </template>
        <template #col-type="{ record }">
          {{ record.type }}
        </template>
        <template #col-size="{ record }">
          {{ record.size }}
        </template>
        <template #col-class="{ record }">
          {{ record.class }}
        </template>
        <template #col-itemClass="{ record }">
          {{ record.itemClassLabel }}
        </template>
        <template #col-manufacturer="{ record }">
          {{ record.manufacturer?.name }}
        </template>
        <template #col-hidden="{ record }">
          <i v-if="record.hidden" class="fad fa-check" />
          <i v-else class="fad fa-times" />
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #col-updatedAt="{ record }">
          {{ l(record.updatedAt, "datetime.formats.short") }}
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="components"
        :query-result-ref="components"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="components"
        :query-result-ref="components"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
