<script lang="ts">
export default {
  name: "AdminModelEditDocksPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import {
  type ModelExtended,
  type Dock,
  type DockInput,
  type FilterOption,
  useDocks as useDocksQuery,
  useCreateDock as useCreateDockMutation,
  useUpdateDock as useUpdateDockMutation,
  useDestroyDock as useDestroyDockMutation,
  getDocksQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

type Props = {
  model: ModelExtended;
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

const docksQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    modelIdEq: props.model.id,
  },
}));

const docksQueryKey = computed(() => getDocksQueryKey(docksQueryParams.value));

const { perPage, page, updatePerPage } = usePagination(docksQueryKey);

const { data, isLoading } = useDocksQuery(docksQueryParams);

const invalidateDocks = async () => {
  await queryClient.invalidateQueries({
    queryKey: getDocksQueryKey(),
  });
};

// Dropdown options
const dockTypeOptions: FilterOption[] = [
  { label: "Vehicle Pad", value: "vehiclepad" },
  { label: "Garage", value: "garage" },
  { label: "Landing Pad", value: "landingpad" },
  { label: "Docking Port", value: "dockingport" },
  { label: "Hangar", value: "hangar" },
];

const shipSizeOptions: FilterOption[] = [
  { label: "Extra Extra Small", value: "extra_extra_small" },
  { label: "Extra Small", value: "extra_small" },
  { label: "Small", value: "small" },
  { label: "Medium", value: "medium" },
  { label: "Large", value: "large" },
  { label: "Extra Large", value: "extra_large" },
  { label: "Capital", value: "capital" },
];

// Edit
const editForm = ref<DockInput>({});

const onStartEdit = (record: Dock) => {
  editForm.value = {
    name: record.name,
    dockType: record.dockType,
    shipSize: record.shipSize,
  };
};

const updateMutation = useUpdateDockMutation({
  mutation: {
    onSettled: invalidateDocks,
  },
});

const onSaveEdit = async () => {
  const id = editableList.value?.editingId;
  if (!id) return;

  await updateMutation.mutateAsync({
    id,
    data: editForm.value,
  });

  editableList.value?.finishEdit();
};

// Delete
const destroyMutation = useDestroyDockMutation({
  mutation: {
    onSettled: invalidateDocks,
  },
});

const onDestroy = async (record: Dock) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create
const createForm = ref<DockInput>({
  modelId: props.model.id,
  dockType: "landingpad",
  shipSize: "medium",
});

const onStartCreate = () => {
  createForm.value = {
    modelId: props.model.id,
    dockType: "landingpad",
    shipSize: "medium",
  };
};

const createMutation = useCreateDockMutation({
  mutation: {
    onSettled: invalidateDocks,
  },
});

const onSaveCreate = async () => {
  await createMutation.mutateAsync({
    data: createForm.value,
  });

  editableList.value?.finishCreate();
};
</script>

<template>
  <div class="d-flex align-items-center justify-content-between">
    <Heading hero>{{ t("headlines.admin.models.edit.docks") }}</Heading>
    <Btn
      :size="BtnSizesEnum.SMALL"
      :disabled="editableList?.creating"
      @click="editableList?.startCreate()"
    >
      <i class="fad fa-plus" />
      {{ t("actions.add") }}
    </Btn>
  </div>

  <InlineEditableList
    empty-name="Docks"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as Dock[]) || []"
    :confirm-destroy-text="t('messages.confirm.dock.destroy')"
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
    @destroy="onDestroy"
  >
    <template #display="{ item }">
      <BasePill uppercase margin-right>{{ item.dockTypeLabel }}</BasePill>
      <BasePill margin-right>{{ item.shipSizeLabel }}</BasePill>
      <span v-if="item.name">{{ item.name }}</span>
    </template>

    <template #edit>
      <FilterGroup
        v-model="editForm.dockType"
        name="edit-dock-type"
        :options="dockTypeOptions"
        :nullable="false"
        label="Dock Type"
      />
      <FilterGroup
        v-model="editForm.shipSize"
        name="edit-ship-size"
        :options="shipSizeOptions"
        :nullable="false"
        label="Ship Size"
      />
      <FormInput
        v-model="editForm.name"
        name="edit-name"
        translation-key="dock.name"
      />
    </template>

    <template #create>
      <FilterGroup
        v-model="createForm.dockType"
        name="create-dock-type"
        :options="dockTypeOptions"
        :nullable="false"
        label="Dock Type"
      />
      <FilterGroup
        v-model="createForm.shipSize"
        name="create-ship-size"
        :options="shipSizeOptions"
        :nullable="false"
        label="Ship Size"
      />
      <FormInput
        v-model="createForm.name"
        name="create-name"
        translation-key="dock.name"
      />
    </template>
  </InlineEditableList>

  <Paginator
    v-if="data"
    :query-result-ref="data"
    :per-page="perPage"
    :update-per-page="updatePerPage"
  />
</template>
