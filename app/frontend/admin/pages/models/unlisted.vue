<script lang="ts">
export default {
  name: "AdminUnlistedModelsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import HeadingSmall from "@/shared/components/base/Heading/Small/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import Paginator from "@/shared/components/Paginator/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useScDataUnlistedModels,
  getScDataUnlistedModelsQueryKey,
  type ScDataUnlistedModel,
  type ScDataUnlistedModelSortEnum,
} from "@/services/fyAdminApi";
import UnlistedModelActions from "@/admin/components/UnlistedModels/Actions/index.vue";

const route = useRoute();

const sorts = computed((): ScDataUnlistedModelSortEnum[] => {
  return route.query.s ? [route.query.s as ScDataUnlistedModelSortEnum] : [];
});

const queryKey = computed(() => {
  return getScDataUnlistedModelsQueryKey(queryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(queryKey);

const queryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: {
      sorts: sorts.value,
    },
  };
});

const {
  data: unlistedModels,
  refetch,
  ...asyncStatus
} = useScDataUnlistedModels(queryParams);

watch(
  () => sorts.value,
  async () => {
    await refetch();
  },
);

// What the export lets us work out. Not a verdict on whether the ship belongs
// in the catalogue -- the game files never say whether a player can own one.
const comparisonLabels: Record<string, string> = {
  identical: "Identical to the ship it extends",
  refitted: "Same hull, different stock loadout",
  structural: "A different machine",
  unrelated: "No base ship",
};

const columns: BaseTableCol<ScDataUnlistedModel>[] = [
  {
    name: "identifier",
    label: "Game-file identifier",
    sortable: true,
  },
  {
    name: "name",
    label: "Name in the export",
    sortable: true,
  },
  {
    name: "comparison",
    label: "Compared to its base ship",
    sortable: true,
    mobile: false,
  },
  {
    name: "baseModel",
    label: "Variant of",
    mobile: false,
  },
  {
    name: "manufacturer",
    label: "Manufacturer",
    mobile: false,
  },
  {
    name: "firstSeenVersion",
    label: "First seen",
    sortable: true,
    mobile: false,
  },
];

const { t } = useI18n();
</script>

<template>
  <Heading hero>
    {{ t("headlines.admin.unlistedModels.index") }}
    <HeadingSmall v-if="unlistedModels">
      {{
        t("headlines.pagination.count", {
          current: unlistedModels?.items.length,
          total: unlistedModels?.meta.pagination?.totalCount,
        })
      }}
    </HeadingSmall>
  </Heading>

  <FilteredList
    name="admin-unlisted-models"
    :records="unlistedModels?.items || []"
    :async-status="asyncStatus"
    hide-loading
    hide-empty
  >
    <template #default="{ loading, refetching, emptyVisible }">
      <BaseTable
        :records="unlistedModels?.items || []"
        primary-key="id"
        :columns="columns"
        :loading="loading || refetching"
        :empty-visible="emptyVisible"
        default-sort="identifier asc"
      >
        <template #col-identifier="{ record }">
          <code>{{ record.identifier }}</code>
        </template>
        <template #col-name="{ record }">
          {{ record.name }}
        </template>
        <template #col-comparison="{ record }">
          {{ record.comparison ? comparisonLabels[record.comparison] : "" }}
        </template>
        <template #col-baseModel="{ record }">
          <router-link
            v-if="record.baseModel"
            :to="{
              name: 'admin-model-edit',
              params: { id: record.baseModel.id },
            }"
          >
            {{ record.baseModel.name }}
          </router-link>
        </template>
        <template #col-manufacturer="{ record }">
          {{ record.manufacturer?.name ?? record.manufacturerCode }}
        </template>
        <template #col-firstSeenVersion="{ record }">
          {{ record.firstSeenVersion }}
        </template>
        <template #actions="{ record }">
          <UnlistedModelActions
            :unlisted-model="record"
            :on-decided="refetch"
          />
        </template>
      </BaseTable>
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="unlistedModels"
        :query-result-ref="unlistedModels"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
