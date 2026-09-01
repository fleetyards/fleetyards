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
  useScDataUnlistedModelBulkIgnore,
  useScDataUnlistedModelBulkMarkAsPaint,
  getScDataUnlistedModelsQueryKey,
  type ScDataUnlistedModel,
  type ScDataUnlistedModelSortEnum,
} from "@/services/fyAdminApi";
import UnlistedModelActions from "@/admin/components/UnlistedModels/Actions/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";

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

const selected = ref<string[]>([]);

const onSelectedChange = (ids: string[]) => {
  selected.value = ids;
};

const deciding = ref(false);

const ignoreMutation = useScDataUnlistedModelBulkIgnore();
const markAsPaintMutation = useScDataUnlistedModelBulkMarkAsPaint();

// A patch's list is mostly one decision repeated, so the two decisions that
// need nothing but the entry are offered for the whole selection. Creating a
// ship and linking one stay per row: each needs a target a person picks.
const decideSelected = async (
  mutation: typeof ignoreMutation | typeof markAsPaintMutation,
) => {
  deciding.value = true;

  await mutation
    .mutateAsync({ data: { ids: selected.value } })
    .then(async () => {
      selected.value = [];
      await refetch();
    })
    .finally(() => {
      deciding.value = false;
    });
};

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
    name: "alreadyThere",
    label: "Already in the catalogue",
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
        selectable
        :selected="selected"
        @selected-change="onSelectedChange"
      >
        <template #selected-actions>
          <BtnGroup>
            <Btn
              v-tooltip="t('actions.unlistedModel.markAsPaintSelected')"
              :disabled="deciding"
              @click="decideSelected(markAsPaintMutation)"
            >
              <i class="fa-duotone fa-palette" />
            </Btn>
            <Btn
              v-tooltip="t('actions.unlistedModel.ignoreSelected')"
              :tone="BtnTonesEnum.DANGER"
              :disabled="deciding"
              @click="decideSelected(ignoreMutation)"
            >
              <i class="fa-duotone fa-eye-slash" />
            </Btn>
          </BtnGroup>
        </template>
        <template #col-identifier="{ record }">
          <code>{{ record.identifier }}</code>
        </template>
        <template #col-name="{ record }">
          {{ record.suggestedName }}
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
        <template #col-alreadyThere="{ record }">
          <router-link
            v-if="record.existingModel"
            :to="{
              name: 'admin-models',
              query: { q: record.existingModel.name },
            }"
          >
            {{ record.existingModel.name }}
          </router-link>
          <span v-else-if="record.existingPaint">
            {{ record.existingPaint.name }}
          </span>
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
