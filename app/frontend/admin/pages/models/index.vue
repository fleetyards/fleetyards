<script lang="ts">
export default {
  name: "AdminModelsPage",
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
import ModelActions from "@/admin/components/Models/Actions/index.vue";
import FilterForm from "@/admin/components/Models/FilterForm/index.vue";
import { useModelFilters } from "@/admin/composables/useModelFilters";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useModels as useModelsQuery,
  useModelsQueryOptions,
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

const modelsQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: filters.value,
    s: sorts.value,
  };
});

const modelsQueryKey = computed(() => {
  return (useModelsQueryOptions(modelsQueryParams) as CustomQueryOptions)
    .queryKey;
});

const { perPage, page, updatePerPage } = usePagination(modelsQueryKey);

const { filters, isFilterSelected } = useModelFilters(() => refetch());

const {
  data: models,
  refetch,
  ...asyncStatus
} = useModelsQuery(modelsQueryParams);

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
    name: "angledView",
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
    name: "rsiId",
    label: "RSI ID",
    field: "rsi_id",
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
    {{ t("headlines.models.index") }}
    <HeadingSmall v-if="models">
      {{
        t("headlines.pagination.count", {
          current: models?.items.length,
          total: models?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn>
      <i class="fa fa-rotate" />
      {{ t("actions.admin.dashboard.reloadModels") }}
    </Btn>
    <Btn>
      <i class="fa fa-rotate" />
      {{ t("actions.admin.dashboard.reloadScData") }}
    </Btn>
    <Btn :to="{ name: 'admin-model-create' }">
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
    <Btn :to="{ name: 'admin-components' }">
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-models"
    :records="models?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty-box
    :is-filter-selected="isFilterSelected"
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, emptyBoxVisible }">
      <BaseTable
        :records="models?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading"
        :empty-box-visible="emptyBoxVisible"
        default-sort="name asc"
        selectable
      >
        <template #col-storeImage="{ record }">
          <LazyImage
            v-if="record.media.storeImage"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.media.storeImage.small"
            alt="Model storeImage"
            shadow
          />
        </template>
        <template #col-rsiStoreImage="{ record }">
          <LazyImage
            v-if="record.media.rsiStoreImage"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.media.rsiStoreImage.small"
            alt="Model rsiStoreImage"
            shadow
          />
        </template>
        <template #col-angledView="{ record }">
          <LazyImage
            v-if="record.media.angledView"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.media.angledView.small"
            alt="Model angledView"
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
            {{ record.manufacturer?.code }} {{ record.name }}
          </router-link>
        </template>
        <template #col-rsiId="{ record }">
          {{ record.rsiId }}
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
          <ModelActions :model="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="models"
        :query-result-ref="models"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="models"
        :query-result-ref="models"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
