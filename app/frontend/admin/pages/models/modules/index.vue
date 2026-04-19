<script lang="ts">
export default {
  name: "AdminModelModulesPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import FilterForm from "@/admin/components/ModelModules/FilterForm/index.vue";
import { useModelModuleFilters } from "@/admin/composables/useModelModuleFilters";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useListModelModules,
  getListModelModulesQueryKey,
  type ModelModule,
} from "@/services/fyAdminApi";

const modulesQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: filters.value,
  };
});

const modulesQueryKey = computed(() => {
  return getListModelModulesQueryKey(modulesQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(modulesQueryKey);

const { filters, isFilterSelected } = useModelModuleFilters(async () => {
  await refetch();
});

const {
  data: modules,
  refetch,
  ...asyncStatus
} = useListModelModules(modulesQueryParams);

const columns: BaseTableCol<ModelModule>[] = [
  {
    name: "storeImage",
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
    name: "models",
    label: "Models",
  },
  {
    name: "manufacturer",
    label: "Manufacturer",
    mobile: false,
  },
  {
    name: "productionStatus",
    label: "Status",
    mobile: false,
    sortable: true,
  },
  {
    name: "pledgePrice",
    label: "Pledge Price",
    mobile: false,
    sortable: true,
  },
  {
    name: "hidden",
    label: "hidden?",
    mobile: false,
    sortable: true,
  },
  {
    name: "active",
    label: "active?",
    mobile: false,
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

const { t, l, toDollar } = useI18n();

const crumbs = [
  {
    to: { name: "admin-models" },
    label: t("nav.admin.models.index"),
  },
  {
    to: { name: "admin-model-modules" },
    label: t("headlines.admin.modelModules.index"),
  },
];
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <Heading hero>
    {{ t("headlines.admin.modelModules.index") }}
    <HeadingSmall v-if="modules">
      {{
        t("headlines.pagination.count", {
          current: modules?.items.length,
          total: modules?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    name="admin-model-modules"
    :records="modules?.items || []"
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
        :records="modules?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="name asc"
        selectable
      >
        <template #col-storeImage="{ record }">
          <ViewImage
            :image="record.media.storeImage"
            size="small"
            alt="image"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            shadow
          />
        </template>
        <template #col-name="{ record }">
          {{ record.name }}
        </template>
        <template #col-models="{ record }">
          <ul v-if="record.models?.length" class="model-modules-models-list">
            <li v-for="model in record.models" :key="model.id">
              <router-link
                :to="{
                  name: 'admin-model-edit',
                  params: { id: model.id },
                }"
              >
                {{ model.name }}
              </router-link>
            </li>
          </ul>
        </template>
        <template #col-manufacturer="{ record }">
          {{ record.manufacturer?.name }}
        </template>
        <template #col-productionStatus="{ record }">
          {{ record.productionStatus }}
        </template>
        <template #col-pledgePrice="{ record }">
          <span class="no-break">{{ toDollar(record.pledgePrice) }}</span>
        </template>
        <template #col-hidden="{ record }">
          <i v-if="record.hidden" class="fa-duotone fa-check" />
          <i v-else class="fa-duotone fa-times" />
        </template>
        <template #col-active="{ record }">
          <i v-if="record.active" class="fa-duotone fa-check" />
          <i v-else class="fa-duotone fa-times" />
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
        v-if="modules"
        :query-result-ref="modules"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="modules"
        :query-result-ref="modules"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>

<style lang="scss" scoped>
.model-modules-models-list {
  list-style: none;
  margin: 0;
  padding: 0;
}
</style>
