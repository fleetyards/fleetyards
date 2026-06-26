<script lang="ts">
export default {
  name: "AdminDestroyedFleetsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import FilterForm from "@/admin/components/DestroyedFleets/FilterForm/index.vue";
import {
  useDestroyedFleets,
  getDestroyedFleetsQueryKey,
  DestroyedFleetsSource,
  type DestroyedFleet,
  type DestroyedFleetQuery,
} from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import DestroyedFleetActions from "@/admin/components/DestroyedFleets/Actions/index.vue";

const { t, l } = useI18n();

const source = ref<DestroyedFleetsSource>(DestroyedFleetsSource.discarded);

const isPurged = computed(() => source.value === DestroyedFleetsSource.purged);

const setSource = async (value: DestroyedFleetsSource) => {
  if (source.value === value) return;

  source.value = value;
  await refetch();
};

const destroyedFleetsQueryKey = computed(() => {
  return getDestroyedFleetsQueryKey(destroyedFleetsQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(destroyedFleetsQueryKey);

const { filters, isFilterSelected } = useFilters<DestroyedFleetQuery>({
  updateCallback: async () => {
    await refetch();
  },
});

const destroyedFleetsQueryParams = computed(() => {
  return {
    page: page.value,
    source: source.value,
    q: {
      ...filters.value,
    },
  };
});

const {
  data: destroyedFleets,
  refetch,
  ...asyncStatus
} = useDestroyedFleets(destroyedFleetsQueryParams);

const columns: BaseTableCol<DestroyedFleet>[] = [
  {
    name: "name",
    label: "Name",
  },
  {
    name: "fid",
    label: "FID",
  },
  {
    name: "source",
    label: "Source",
    mobile: false,
  },
  {
    name: "destroyedAt",
    label: "Destroyed At",
    mobile: false,
  },
  {
    name: "destroyedBy",
    label: "Destroyed By",
    mobile: false,
  },
];
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.destroyedFleets.index") }}
    <HeadingSmall v-if="destroyedFleets">
      {{
        t("headlines.pagination.count", {
          current: destroyedFleets?.items.length,
          total: destroyedFleets?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <BtnGroup inline>
    <Btn
      :active="source === DestroyedFleetsSource.discarded"
      @click="setSource(DestroyedFleetsSource.discarded)"
    >
      {{ t("labels.destroyedFleets.discarded") }}
    </Btn>
    <Btn
      :active="source === DestroyedFleetsSource.purged"
      @click="setSource(DestroyedFleetsSource.purged)"
    >
      {{ t("labels.destroyedFleets.purged") }}
    </Btn>
  </BtnGroup>

  <Panel v-if="isPurged" :variant="PanelVariantsEnum.ERROR">
    {{ t("texts.admin.destroyedFleets.purgedWarning") }}
  </Panel>

  <FilteredList
    name="admin-destroyed-fleets"
    :records="destroyedFleets?.items || []"
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
        :records="destroyedFleets?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
      >
        <template #col-name="{ record }">
          {{ record.name }}
        </template>
        <template #col-fid="{ record }">
          {{ record.fid }}
        </template>
        <template #col-source="{ record }">
          {{ t(`labels.destroyedFleets.${record.source}`) }}
        </template>
        <template #col-destroyedAt="{ record }">
          {{ l(record.destroyedAt, "datetime.formats.short") }}
        </template>
        <template #col-destroyedBy="{ record }">
          {{ record.destroyedBy || "—" }}
        </template>
        <template #actions="{ record }">
          <DestroyedFleetActions :destroyed-fleet="record" />
        </template>
      </BaseTable>
    </template>
    <template #pagination-top>
      <Paginator
        v-if="destroyedFleets"
        :query-result-ref="destroyedFleets"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="destroyedFleets"
        :query-result-ref="destroyedFleets"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
