<script lang="ts">
export default {
  name: "AdminModelsModulesPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
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
  getModelsQueryKey,
  type Model,
} from "@/services/fyAdminApi";

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
    q: getQuery(),
    s: sorts.value,
  };
});

const modelsQueryKey = computed(() => {
  return getModelsQueryKey(modelsQueryParams);
});

const { perPage, page, updatePerPage } = usePagination(modelsQueryKey);

const { getQuery, isFilterSelected } = useModelFilters(() => refetch());

const {
  data: models,
  refetch,
  ...asyncStatus
} = useModelsQuery(modelsQueryParams);

const columns: BaseTableCol<Model>[] = [
  {
    name: "storeImage",
    label: "",
    alignment: "center",
  },
  {
    name: "rsiStoreImage",
    label: "",
    mobile: false,
  },
  {
    name: "angledView",
    label: "",
    alignment: "center",
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
    attributeKey: "rsiId",
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
];

const { t } = useI18n();
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
    <Btn :to="{ name: 'admin-model-create' }">
      <i class="fa fa-plus" />
      {{ t("actions.create") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-models"
    :records="models?.items || []"
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
        :records="models?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading"
        :empty-visible="emptyVisible"
        default-sort="name asc"
        selectable
      >
        <template #loader="{ loading }">
          <Loader :loading="loading" admin />
        </template>
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
            v-if="record.media.storeImage"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.media.storeImage.smallUrl"
            alt="Model rsiStoreImage"
            shadow
          />
        </template>
        <template #col-angledView="{ record }">
          <LazyImage
            v-if="record.media.angledView"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            :src="record.media.angledView.smallUrl"
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
