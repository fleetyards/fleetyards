<script lang="ts">
export default {
  name: "MaintenanceImportsPage",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import BasePill from "@/shared/components/base/Pill/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";

import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useImports,
  useCleanupBulkImports,
  type Import,
  ImportStatusEnum,
} from "@/services/fyAdminApi";
import { useImportLoaders } from "@/admin/composables/useImportLoaders";
import { useComlink } from "@/shared/composables/useComlink";
import { useImportUpdates } from "@/admin/composables/useImportUpdates";
import FilterForm from "@/admin/components/Imports/FilterForm/index.vue";
import { useFilters } from "@/shared/composables/useFilters";
import type { ImportQuery } from "@/services/fyAdminApi";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

const { t, l } = useI18n();
const router = useRouter();
const queryClient = useQueryClient();
const { displaySuccess, displayInfo, displayAlert } = useAppNotifications();

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

const comlink = useComlink();
const { isGroupRunning } = useImportLoaders();

const isLoadingShipMatrix = isGroupRunning("shipMatrix");
const isLoadingScData = isGroupRunning("scData");

const openLoaders = (group: "shipMatrix" | "scData") => {
  comlink.emit("open-modal", {
    component: () => import("@/admin/components/Imports/LoadModal/index.vue"),
    props: { group },
  });
};

/*
 * A stuck import is not a state of its own -- the row still says `started`
 * because the job died before anything could mark it. Nothing but an admin can
 * tell the difference between that and a run that is simply slow, which is why
 * the rows to write off are ticked rather than swept.
 */
const selected = ref<string[]>([]);

const onSelectedChange = (ids: string[]) => {
  selected.value = ids;
};

const cleanupMutation = useCleanupBulkImports();

// The selection is spent once the action lands: the rows it named have moved
// on, and leaving them ticked only invites a second run over them.
const cleanupSelected = async () => {
  try {
    const { count } = await cleanupMutation.mutateAsync({
      data: { ids: selected.value },
    });

    selected.value = [];
    void queryClient.invalidateQueries({ queryKey: ["imports"] });

    if (count === 0) {
      displayInfo({ text: t("messages.admin.imports.noneRunning") });

      return;
    }

    displaySuccess({ text: t("messages.admin.imports.cleanedUp", { count }) });
  } catch {
    displayAlert({ text: t("messages.admin.imports.cleanupError") });
  }
};

const formatType = (type: string): string =>
  type
    .replace("Imports::", "")
    .replace("::", " ")
    .replace(/([A-Z])/g, " $1")
    .replace(/^ /, "")
    .trim();

const statusVariant = (status: ImportStatusEnum): `${PillVariantsEnum}` => {
  switch (status) {
    case ImportStatusEnum.FINISHED:
      return PillVariantsEnum.SUCCESS;
    case ImportStatusEnum.FAILED:
      return PillVariantsEnum.DANGER;
    case ImportStatusEnum.STARTED:
      return PillVariantsEnum.WARNING;
    default:
      return PillVariantsEnum.DEFAULT;
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
    <!-- Running shows on the icon rather than through `loading`, which
         disables the button: a load already running must not keep the
         others in its group out of reach. -->
    <Btn
      :size="BtnSizesEnum.MD"
      :aria-label="t('actions.admin.imports.loadShipMatrix')"
      :aria-busy="isLoadingShipMatrix"
      mobile-icon-only
      data-test="imports-load-ship-matrix"
      @click="openLoaders('shipMatrix')"
    >
      <i
        :class="
          isLoadingShipMatrix
            ? 'fa-duotone fa-spinner-third fa-spin'
            : 'fa fa-rotate'
        "
      />
      {{ t("actions.admin.imports.loadShipMatrix") }}
    </Btn>
    <Btn
      :size="BtnSizesEnum.MD"
      :aria-label="t('actions.admin.imports.loadScData')"
      :aria-busy="isLoadingScData"
      mobile-icon-only
      data-test="imports-load-sc-data"
      @click="openLoaders('scData')"
    >
      <i
        :class="
          isLoadingScData
            ? 'fa-duotone fa-spinner-third fa-spin'
            : 'fa fa-database'
        "
      />
      {{ t("actions.admin.imports.loadScData") }}
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
        selectable
        :selected="selected"
        @row-click="onRowClick"
        @selected-change="onSelectedChange"
      >
        <template #selected-actions>
          <Btn
            v-tooltip="t('actions.admin.imports.cleanupSelected')"
            :tone="BtnTonesEnum.DANGER"
            :loading="cleanupMutation.isPending.value"
            :confirm="t('messages.confirm.import.cleanupSelected')"
            :aria-label="t('actions.admin.imports.cleanupSelected')"
            @click="cleanupSelected"
          >
            <i class="fa-duotone fa-hourglass-end" />
          </Btn>
        </template>
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
        :query-result-ref="importsList"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        :query-result-ref="importsList"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
