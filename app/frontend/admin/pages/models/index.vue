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
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import ModelActions from "@/admin/components/Models/Actions/index.vue";
import FilterForm from "@/admin/components/Models/FilterForm/index.vue";
import { useModelFilters } from "@/admin/composables/useModelFilters";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  useModels as useModelsQuery,
  getModelsQueryKey,
  type Model,
} from "@/services/fyAdminApi";
import {
  useModelsStore,
  AdminModelTableViewColsEnum,
  AdminModelTableViewImageColsEnum,
} from "@/admin/stores/models";
import { useBreadCrumbsStore } from "@/shared/stores/breadCrumbs";
import {
  useReloadModelsMatrix,
  useReloadModelsScData,
} from "@/services/fyAdminApi";
import { useImportLoading } from "@/admin/composables/useImportLoading";
import { ImportTypeEnum } from "@/services/fyAdminApi";

const { isImporting: isImportingMatrix } = useImportLoading(
  ImportTypeEnum.IMPORTS_MODELS_IMPORT,
);

const { isImporting: isImportingScData } = useImportLoading(
  ImportTypeEnum.IMPORTS_SC_DATA_MODELS_IMPORT,
);

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

const { getQuery, isFilterSelected } = useModelFilters(async () => {
  await refetch();
});

const {
  data: models,
  refetch,
  ...asyncStatus
} = useModelsQuery(modelsQueryParams);

const modelsStore = useModelsStore();

const extraColumns = computed<BaseTableCol<Model>[]>(() => {
  return Object.values(AdminModelTableViewColsEnum)
    .map((col) => {
      return {
        name: col,
        label: t(`labels.models.table.columns.${col}`),
        sortable: true,
      };
    })
    .filter((col) => {
      return modelsStore.tableViewCols.includes(col.name);
    });
});

const extraImageColumns = computed(() => {
  return Object.values(AdminModelTableViewImageColsEnum)
    .map((col) => {
      return {
        name: col,
        label: "",
        width: col.endsWith("Wide") ? "270px" : "120px",
        centered: true,
      };
    })
    .filter((col) => {
      return modelsStore.tableViewImageCols.includes(col.name);
    });
});

const tableColumns = computed<BaseTableCol<Model>[]>(() => {
  return [
    ...extraImageColumns.value,
    {
      name: "name",
      label: t("labels.vehicle.name"),
      width: "auto",
      sortable: true,
    },
    ...extraColumns.value,
  ];
});

const { t, l, toNumber, toUEC, toDollar } = useI18n();

const angledImage = (record: Model) => {
  if (record && record.media.angledViewColored) {
    return record.media.angledViewColored;
  }

  return record.media.angledView;
};

const comlink = useComlink();

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/Models/DisplayOptionsModal/index.vue"),
  });
};

const reloadMatrixMutation = useReloadModelsMatrix();
const reloadScDataMutation = useReloadModelsScData();

const isReloadingMatrix = computed(
  () => isImportingMatrix.value || reloadMatrixMutation.isPending.value,
);
const isReloadingScData = computed(
  () => isImportingScData.value || reloadScDataMutation.isPending.value,
);

const reloadModels = async () => {
  await reloadMatrixMutation.mutateAsync();
};

const reloadScData = async () => {
  await reloadScDataMutation.mutateAsync();
};

const breadcrumbsStore = useBreadCrumbsStore();

watch(
  () => route.query,
  () => {
    breadcrumbsStore.setCrumbs("admin-models", route.fullPath);
  },
  { immediate: true },
);

watch(
  () => models?.value,
  () => {
    modelsStore.setList(models?.value);
  },
  { immediate: true },
);
</script>

<template>
  <Heading hero>
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
    <Btn
      :size="BtnSizesEnum.SMALL"
      :loading="isReloadingMatrix"
      :confirm="t('messages.confirm.model.reloadMatrix')"
      spinner
      @click="reloadModels"
    >
      <i class="fa fa-rotate" />
      {{ t("actions.admin.dashboard.reloadModels") }}
    </Btn>
    <Btn
      :size="BtnSizesEnum.SMALL"
      :loading="isReloadingScData"
      :confirm="t('messages.confirm.model.reloadScData')"
      spinner
      @click="reloadScData"
    >
      <i class="fa fa-rotate" />
      {{ t("actions.admin.dashboard.reloadScData") }}
    </Btn>
    <Btn :size="BtnSizesEnum.SMALL" :to="{ name: 'admin-model-create' }">
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
    <template #actions-right>
      <Btn
        :aria-label="t('actions.models.openTableConfiguration')"
        :size="BtnSizesEnum.SMALL"
        @click="openDisplayOptionsModal"
      >
        <i class="fa-duotone fa-sliders" />
      </Btn>
    </template>
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="models?.items || []"
        primary-key="id"
        :columns="tableColumns"
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
        <template #col-rsiStoreImage="{ record }">
          <ViewImage
            :image="record.media.storeImage"
            size="small"
            alt="image"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            shadow
          />
        </template>
        <template #col-angledView="{ record }">
          <ViewImage
            :image="angledImage(record)"
            size="small"
            alt="image"
            :variant="LazyImageVariantsEnum.WIDE_SMALL"
            transparent
            without-fallback
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
        <template #col-manufacturerName="{ record }">
          {{ record.manufacturer?.name }}
        </template>
        <template #col-length="{ record }">
          <span class="no-break">{{
            toNumber(record.metrics.length || "", "distance")
          }}</span>
        </template>
        <template #col-beam="{ record }">
          <span class="no-break">{{
            toNumber(record.metrics.beam || "", "distance")
          }}</span>
        </template>
        <template #col-height="{ record }">
          <span class="no-break">{{
            toNumber(record.metrics.height || "", "distance")
          }}</span>
        </template>
        <template #col-mass="{ record }">
          <span class="no-break">{{
            toNumber(record.metrics.mass || "", "weight")
          }}</span>
        </template>
        <template #col-cargo="{ record }">
          <span class="no-break">{{
            toNumber(record.metrics.cargo || "", "cargo")
          }}</span>
        </template>
        <template #col-hydrogenFuelTankSize="{ record }">
          <span class="no-break">{{
            toNumber(record.metrics.hydrogenFuelTankSize || "", "cargo")
          }}</span>
        </template>
        <template #col-quantumFuelTankSize="{ record }">
          <span class="no-break">{{
            toNumber(record.metrics.quantumFuelTankSize || "", "cargo")
          }}</span>
        </template>
        <template #col-minCrew="{ record }">
          <span class="no-break">{{
            toNumber(record.crew.min || "", "people")
          }}</span>
        </template>
        <template #col-maxCrew="{ record }">
          <span class="no-break">{{
            toNumber(record.crew.max || "", "people")
          }}</span>
        </template>
        <template #col-groundMaxSpeed="{ record }">
          <span class="no-break">{{
            toNumber(record.speeds.groundMaxSpeed || "", "speed")
          }}</span>
        </template>
        <template #col-scmSpeed="{ record }">
          <span class="no-break">{{
            toNumber(record.speeds.scmSpeed || "", "speed")
          }}</span>
        </template>
        <template #col-maxSpeed="{ record }">
          <span class="no-break">{{
            toNumber(record.speeds.maxSpeed || "", "speed")
          }}</span>
        </template>
        <template #col-productionStatus="{ record }">
          {{ t(`labels.model.productionStatus.${record.productionStatus}`) }}
        </template>
        <template #col-price="{ record }">
          <!-- eslint-disable vue/no-v-html -->
          <div
            v-tooltip="{ content: toUEC(record.price), html: true }"
            class="no-break"
            v-html="toUEC(record.price)"
          />
          <!-- eslint-enable vue/no-v-html -->
        </template>
        <template #col-pledgePrice="{ record }">
          <span class="no-break">{{ toDollar(record.pledgePrice) }}</span>
        </template>
        <template #col-rsiId="{ record }">
          {{ record.rsiId }}
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
