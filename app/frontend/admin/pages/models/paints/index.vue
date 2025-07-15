<script lang="ts">
export default {
  name: "AdminModelsModulesPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableColumn } from "@/shared/components/base/Table/types";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import ModelPaintActions from "@/admin/components/ModelPaints/Actions/index.vue";
import FilterForm from "@/admin/components/ModelPaints/FilterForm/index.vue";
import { useModelPaintFilters } from "@/admin/composables/useModelPaintFilters";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  usePaintsQueryOptions,
  usePaints as usePaintsQuery,
} from "@/services/fyAdminApi";
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

const paintsQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: filters.value,
    s: sorts.value,
  };
});

const paintsQueryKey = computed(() => {
  return (usePaintsQueryOptions(paintsQueryParams) as CustomQueryOptions)
    .queryKey;
});

const { perPage, page, updatePerPage } = usePagination(paintsQueryKey);

const { filters, isFilterSelected } = useModelPaintFilters(() => refetch());

const {
  data: paints,
  refetch,
  ...asyncStatus
} = usePaintsQuery(paintsQueryParams);

const columns: BaseTableColumn[] = [
  {
    name: "storeImage",
    label: "",
    centered: true,
  },
  {
    name: "rsiStoreImage",
    label: "",
    centered: true,
    mobile: false,
  },
  {
    name: "name",
    label: "Name",
    sortable: true,
  },
  {
    name: "model",
    label: "Model",
    field: "model_slug",
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

const { t, l } = useI18n();
</script>

<template>
  <Heading>
    {{ t("headlines.admin.modelPaints.index") }}
    <HeadingSmall v-if="paints">
      {{
        t("headlines.pagination.count", {
          current: paints?.items.length,
          total: paints?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn :to="{ name: 'admin-model-paint-create' }">
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-model-paints"
    :records="paints?.items || []"
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
        :records="paints?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading"
        :empty-visible="emptyVisible"
        default-sort="name asc"
        selectable
      >
        <template #col-storeImage="{ record }">
          <LazyImage
            v-if="record.media.storeImage"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.media.storeImage.smallUrl"
            alt="Model storeImage"
            shadow
          />
        </template>
        <template #col-rsiStoreImage="{ record }">
          <LazyImage
            v-if="record.media.rsiStoreImage"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.media.rsiStoreImage.smallUrl"
            alt="Model rsiStoreImage"
            shadow
          />
        </template>
        <template #col-name="{ record }">
          <router-link
            :to="{
              name: 'admin-model-edit',
              params: {
                id: record.id,
              },
            }"
          >
            {{ record.name }}
          </router-link>
        </template>
        <template #col-model="{ record }">
          {{ record.model.name }}
        </template>
        <template #col-hidden="{ record }">
          <i v-if="record.hidden" class="fad fa-check" />
          <i v-else class="fad fa-times" />
        </template>
        <template #col-active="{ record }">
          <i v-if="record.active" class="fad fa-check" />
          <i v-else class="fad fa-times" />
        </template>
        <template #col-createdAt="{ record }">
          {{ l(record.createdAt, "datetime.formats.short") }}
        </template>
        <template #col-updatedAt="{ record }">
          {{ l(record.updatedAt, "datetime.formats.short") }}
        </template>
        <template #actions="{ record }">
          <ModelPaintActions :model-paint="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="paints"
        :query-result-ref="paints"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="paints"
        :query-result-ref="paints"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
