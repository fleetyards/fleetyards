<script lang="ts">
export default {
  name: "MaintenanceImportsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import BasePill from "@/shared/components/base/Pill/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useImports,
  useReloadModelsMatrix,
  useReloadModelsScData,
  useReloadPaints,
  useReloadModules,
  useReloadLoaners,
  type Import,
  ImportStatusEnum,
  ImportTypeEnum,
} from "@/services/fyAdminApi";
import { useImportLoading } from "@/admin/composables/useImportLoading";
import { useImportUpdates } from "@/admin/composables/useImportUpdates";
import FilterForm from "@/admin/components/Imports/FilterForm/index.vue";
import { useFilters } from "@/shared/composables/useFilters";
import type { ImportQuery } from "@/services/fyAdminApi";

const { t, l } = useI18n();
const router = useRouter();

const onRowClick = async (record: Import) => {
  await router.push({ name: "import", params: { id: record.id } });
};

const queryKey = "admin-imports";
const { perPage, page, updatePerPage } = usePagination(queryKey);

const { getQuery, isFilterSelected } = useFilters<ImportQuery>();

const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: getQuery() as ImportQuery,
}));

const { data: importsList, ...asyncStatus } = useImports(queryParams);

useImportUpdates(computed(() => true));

const reloadMatrixMutation = useReloadModelsMatrix();
const reloadScDataMutation = useReloadModelsScData();
const reloadPaintsMutation = useReloadPaints();
const reloadModulesMutation = useReloadModules();
const reloadLoanersMutation = useReloadLoaners();

const { isImporting: isImportingMatrix } = useImportLoading(
  ImportTypeEnum.IMPORTS_MODELS_IMPORT,
);
const { isImporting: isImportingScData } = useImportLoading([
  ImportTypeEnum.IMPORTS_SC_DATA_ALL_IMPORT,
  ImportTypeEnum.IMPORTS_SC_DATA_MODELS_IMPORT,
]);
const { isImporting: isImportingPaints } = useImportLoading(
  ImportTypeEnum.IMPORTS_PAINTS_IMPORT,
);
const { isImporting: isImportingModules } = useImportLoading(
  ImportTypeEnum.IMPORTS_MODULES_IMPORT,
);

const isReloadingMatrix = computed(
  () => isImportingMatrix.value || reloadMatrixMutation.isPending.value,
);
const isReloadingScData = computed(
  () => isImportingScData.value || reloadScDataMutation.isPending.value,
);
const isReloadingPaints = computed(
  () => isImportingPaints.value || reloadPaintsMutation.isPending.value,
);
const isReloadingModules = computed(
  () => isImportingModules.value || reloadModulesMutation.isPending.value,
);
const isReloadingLoaners = computed(
  () => reloadLoanersMutation.isPending.value,
);

const reloadModels = () => reloadMatrixMutation.mutateAsync();
const reloadScData = () => reloadScDataMutation.mutateAsync();
const reloadPaints = () => reloadPaintsMutation.mutateAsync();
const reloadModules = () => reloadModulesMutation.mutateAsync();
const reloadLoaners = () => reloadLoanersMutation.mutateAsync();

const formatType = (type: string): string =>
  type
    .replace("Imports::", "")
    .replace("::", " ")
    .replace(/([A-Z])/g, " $1")
    .replace(/^ /, "")
    .trim();

const statusVariant = (
  status: ImportStatusEnum,
): "default" | "success" | "warning" | "danger" => {
  switch (status) {
    case ImportStatusEnum.FINISHED:
      return "success";
    case ImportStatusEnum.FAILED:
      return "danger";
    case ImportStatusEnum.STARTED:
      return "warning";
    default:
      return "default";
  }
};

const columns: BaseTableCol<Import>[] = [
  { name: "type", label: t("labels.imports.type"), width: "auto" },
  {
    name: "status",
    label: t("labels.imports.status"),
    width: "120px",
    alignment: "center",
  },
  {
    name: "version",
    label: t("labels.imports.version"),
    width: "120px",
    mobile: false,
  },
  {
    name: "requestedBy",
    label: t("labels.imports.requestedBy"),
    width: "160px",
    mobile: false,
  },
  {
    name: "startedAt",
    label: t("labels.imports.startedAt"),
    width: "180px",
    mobile: false,
  },
  {
    name: "finishedAt",
    label: t("labels.imports.finishedAt"),
    width: "180px",
    mobile: false,
  },
  {
    name: "info",
    label: t("labels.imports.info"),
    width: "auto",
    mobile: false,
  },
];
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.imports.index") }}
    <HeadingSmall v-if="importsList">
      {{
        t("headlines.pagination.count", {
          current: importsList?.items.length,
          total: importsList?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <Teleport to="#header-right">
    <Btn
      :size="BtnSizesEnum.SMALL"
      :loading="isReloadingMatrix"
      :confirm="t('messages.confirm.model.reloadMatrix')"
      :aria-label="t('actions.admin.dashboard.reloadModels')"
      mobile-icon-only
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
      :aria-label="t('actions.admin.dashboard.reloadScData')"
      mobile-icon-only
      spinner
      @click="reloadScData"
    >
      <i class="fa fa-database" />
      {{ t("actions.admin.dashboard.reloadScData") }}
    </Btn>
    <Btn
      :size="BtnSizesEnum.SMALL"
      :loading="isReloadingModules"
      :confirm="t('messages.confirm.model.reloadModules')"
      :aria-label="t('actions.admin.dashboard.reloadModules')"
      mobile-icon-only
      spinner
      @click="reloadModules"
    >
      <i class="fa fa-puzzle" />
      {{ t("actions.admin.dashboard.reloadModules") }}
    </Btn>
    <Btn
      :size="BtnSizesEnum.SMALL"
      :loading="isReloadingPaints"
      :confirm="t('messages.confirm.model.reloadPaints')"
      :aria-label="t('actions.admin.dashboard.reloadPaints')"
      mobile-icon-only
      spinner
      @click="reloadPaints"
    >
      <i class="fa fa-palette" />
      {{ t("actions.admin.dashboard.reloadPaints") }}
    </Btn>
    <Btn
      :size="BtnSizesEnum.SMALL"
      :loading="isReloadingLoaners"
      :confirm="t('messages.confirm.model.reloadLoaners')"
      :aria-label="t('actions.admin.dashboard.reloadLoaners')"
      mobile-icon-only
      spinner
      @click="reloadLoaners"
    >
      <i class="fa fa-handshake" />
      {{ t("actions.admin.dashboard.reloadLoaners") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="admin-imports"
    :records="importsList?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
    hide-loading
    hide-empty
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="importsList?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="created_at desc"
        row-clickable
        @row-click="onRowClick"
      >
        <template #col-type="{ record }">
          {{ formatType(record.type) }}
        </template>
        <template #col-status="{ record }">
          <BasePill :variant="statusVariant(record.status)" uppercase>
            {{ t(`labels.imports.statuses.${record.status}`) }}
          </BasePill>
        </template>
        <template #col-version="{ record }">
          <span class="no-break">{{ record.version || "-" }}</span>
        </template>
        <template #col-requestedBy="{ record }">
          <span class="no-break">
            {{
              record.adminUser?.username || record.user?.username || "system"
            }}
          </span>
        </template>
        <template #col-startedAt="{ record }">
          {{
            record.startedAt
              ? l(record.startedAt, "datetime.formats.short")
              : "-"
          }}
        </template>
        <template #col-finishedAt="{ record }">
          <template v-if="record.failedAt">
            {{ l(record.failedAt, "datetime.formats.short") }}
          </template>
          <template v-else-if="record.finishedAt">
            {{ l(record.finishedAt, "datetime.formats.short") }}
          </template>
          <template v-else>-</template>
        </template>
        <template #col-info="{ record }">
          <span v-if="record.info" class="text-muted">{{ record.info }}</span>
          <template v-else>-</template>
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="importsList"
        :query-result-ref="importsList"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="importsList"
        :query-result-ref="importsList"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
