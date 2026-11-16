<script lang="ts">
export default {
  name: "AdminModelModuleEditCargoHoldsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import {
  type ModelModule,
  type AdminCargoHold,
  type CargoHoldInput,
  type FilterOption,
  useListCargoHolds as useListCargoHoldsQuery,
  useUpdateCargoHold as useUpdateCargoHoldMutation,
  getListCargoHoldsQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import {
  formatMaxContainer,
  hasLoadableLimit,
  humanizeHoldName,
  loadableContainerSizes,
} from "@/shared/utils/CargoHolds";
// Registered globally as `Select`, so `<BaseSelect>` resolves to nothing
// without this.
import BaseSelect from "@/shared/components/base/Select/index.vue";

type Props = {
  modelModule: ModelModule;
};

const props = defineProps<Props>();

const { t } = useI18n();
const queryClient = useQueryClient();

const editableList = ref<{
  editingId: string | null;
  creating: boolean;
  startCreate: () => void;
  finishEdit: () => void;
  finishCreate: () => void;
} | null>(null);

const queryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    parentTypeEq: "ModelModule",
    parentIdEq: props.modelModule.id,
  },
}));

const { perPage, page, updatePerPage } = usePagination();

const { data, isLoading } = useListCargoHoldsQuery(queryParams);

const invalidateCargoHolds = () =>
  queryClient.invalidateQueries({
    queryKey: getListCargoHoldsQueryKey(),
  });

// Edit
const editForm = ref<CargoHoldInput>({});
const editingHold = ref<AdminCargoHold>();

const loadableSizeOptions = computed<FilterOption[]>(() =>
  loadableContainerSizes(editingHold.value).map((size) => ({
    label: `${size} SCU`,
    value: size,
  })),
);

const onStartEdit = (hold: AdminCargoHold) => {
  editingHold.value = hold;
  editForm.value = {
    maxLoadableContainerSizeScu: hold.maxLoadableContainerSizeScu ?? undefined,
  };
};

const updateMutation = useUpdateCargoHoldMutation({
  mutation: {
    onSettled: invalidateCargoHolds,
  },
});

const toNumberOrNull = (val: unknown): number | null => {
  if (val === "" || val === undefined || val === null) return null;
  const num = Number(val);
  return Number.isNaN(num) ? null : num;
};

const onSaveEdit = async () => {
  const id = editableList.value?.editingId;
  if (!id) return;

  await updateMutation.mutateAsync({
    id,
    data: {
      maxLoadableContainerSizeScu: toNumberOrNull(
        editForm.value.maxLoadableContainerSizeScu,
      ),
    },
  });

  editableList.value?.finishEdit();
};

const formatDimensions = (hold: AdminCargoHold) =>
  `${hold.dimensionX} x ${hold.dimensionY} x ${hold.dimensionZ}m`;
</script>

<template>
  <Heading hero>{{ t("headlines.admin.modelModules.cargoHolds") }}</Heading>

  <FormTextarea
    v-if="modelModule.cargoHolds"
    :model-value="JSON.stringify(modelModule.cargoHolds, undefined, 4)"
    name="cargoHolds"
    translation-key="model.cargoHolds"
    class="base-data-output"
    disabled
  />

  <hr />

  <InlineEditableList
    empty-name="Cargo Holds"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as AdminCargoHold[]) || []"
    hide-destroy
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
  >
    <template #display="{ item }">
      <span style="display: flex; gap: 8px; align-items: center">
        <strong>{{
          item.name ? humanizeHoldName(item.name) : `Hold #${item.position}`
        }}</strong>
        <span class="text-muted">
          {{ formatDimensions(item) }} &middot; {{ item.capacityScu }} SCU
        </span>
      </span>
      <span :class="{ 'text-muted': !hasLoadableLimit(item) }">
        Max crate: {{ formatMaxContainer(item) }}
      </span>
    </template>

    <template #headline="{ item }">
      {{ item.name ? humanizeHoldName(item.name) : `Hold #${item.position}` }}
    </template>

    <template #edit>
      <BaseSelect
        v-model="editForm.maxLoadableContainerSizeScu"
        name="maxLoadableContainerSizeScu"
        :options="loadableSizeOptions"
        translation-key="cargoHold.maxLoadableContainerSizeScu"
        unsorted
      />
    </template>
  </InlineEditableList>

  <Paginator
    :query-result-ref="data"
    :per-page="perPage"
    :update-per-page="updatePerPage"
  />
</template>
