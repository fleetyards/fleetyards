<script lang="ts">
export default {
  name: "AdminDocksEditor",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import {
  type Dock,
  type DockInput,
  type DockInputParentType,
  type FilterOption,
  useDocks as useDocksQuery,
  useCreateDock as useCreateDockMutation,
  useUpdateDock as useUpdateDockMutation,
  useDestroyDock as useDestroyDockMutation,
  getDocksQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
// Registered globally as `Select`, so `<BaseSelect>` resolves to nothing
// without this and the two dropdowns render as empty comments.
import BaseSelect from "@/shared/components/base/Select/index.vue";
import {
  InputAlignmentsEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";

// A dock hangs off whatever carries it -- a ship, or a module such as the
// Galaxy's medic bay with its vehicle lift. Both admin pages render this.
interface Props {
  parentId: string;
  parentType: DockInputParentType;
  headline: string;
}

const props = defineProps<Props>();

const { t } = useI18n();
const queryClient = useQueryClient();
const { displayAlert } = useAppNotifications();

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
    parentIdEq: props.parentId,
    parentTypeEq: props.parentType,
  },
}));

const docksQueryKey = computed(() => getDocksQueryKey(docksQueryParams.value));

const { perPage, page, updatePerPage } = usePagination(docksQueryKey);

const { data, isLoading } = useDocksQuery(docksQueryParams);

const invalidateDocks = () =>
  queryClient.invalidateQueries({
    queryKey: getDocksQueryKey(),
  });

// Dropdown options
// `vehiclepad` is deliberately absent: every row that had it moved to the cargo
// grid, and nothing new should become one.
const dockTypeOptions = computed<FilterOption[]>(() =>
  ["hangar", "landingpad", "cargogrid", "garage", "dockingport"].map(
    (value) => ({ label: t(`labels.dockTypes.${value}`), value }),
  ),
);

// A ladder, so the order is the point -- alphabetical put Capital first and
// Extra Large between the two smallest. Hence `unsorted` on the select.
const shipSizeOptions = computed<FilterOption[]>(() =>
  [
    "extra_extra_small",
    "extra_small",
    "small",
    "medium",
    "large",
    "extra_large",
    "capital",
  ].map((value) => ({ label: t(`labels.shipSizes.${value}`), value })),
);

// Edit
const editForm = ref<DockInput>({});

const onStartEdit = (record: Dock) => {
  editForm.value = {
    name: record.name,
    dockType: record.dockType,
    shipSize: record.shipSize,
    length: record.length,
    beam: record.beam,
    height: record.height,
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

  try {
    await updateMutation.mutateAsync({ id, data: editForm.value });
  } catch {
    displayAlert({ text: t("messages.dock.update.failure") });
    return;
  }

  editableList.value?.finishEdit();
};

// Delete
const destroyMutation = useDestroyDockMutation({
  mutation: {
    onSettled: invalidateDocks,
  },
});

const onDestroy = async (record: Dock) => {
  try {
    await destroyMutation.mutateAsync({ id: record.id });
  } catch {
    displayAlert({ text: t("messages.dock.destroy.failure") });
  }
};

// Create
const createForm = ref<DockInput>({
  parentId: props.parentId,
  parentType: props.parentType,
});

const onStartCreate = () => {
  createForm.value = {
    parentId: props.parentId,
    parentType: props.parentType,
  };
};

const createMutation = useCreateDockMutation({
  mutation: {
    onSettled: invalidateDocks,
  },
});

const onSaveCreate = async () => {
  try {
    await createMutation.mutateAsync({ data: createForm.value });
  } catch {
    displayAlert({ text: t("messages.dock.create.failure") });
    return;
  }

  editableList.value?.finishCreate();
};
</script>

<template>
  <div class="flex items-center justify-between mb-4">
    <Heading hero>{{ headline }}</Heading>
    <Btn
      :disabled="editableList?.creating"
      @click="editableList?.startCreate()"
    >
      <i class="fa-duotone fa-plus" />
      {{ t("actions.add") }}
    </Btn>
  </div>

  <InlineEditableList
    :empty-name="t('headlines.admin.models.edit.docks')"
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
      <!-- An unmeasured berth answers nothing, so say so rather than leaving
           the row looking complete. -->
      <span class="docks-editor__dimensions">
        <template v-if="item.length && item.beam && item.height">
          {{ item.length }} × {{ item.beam }} × {{ item.height }} m
        </template>
        <template v-else>
          {{ t("labels.dock.unmeasured") }}
        </template>
      </span>
    </template>

    <template #edit>
      <BaseSelect
        v-model="editForm.dockType"
        name="edit-dock-type"
        :options="dockTypeOptions"
        :label="t('labels.dock.dockType')"
      />
      <BaseSelect
        v-model="editForm.shipSize"
        name="edit-ship-size"
        :options="shipSizeOptions"
        unsorted
        :label="t('labels.dock.shipSize')"
      />
      <FormInput
        v-model="editForm.name"
        name="edit-name"
        translation-key="dock.name"
      />
      <FormInput
        v-model="editForm.length"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
        name="edit-length"
        translation-key="dock.length"
        :step="0.1"
      />
      <FormInput
        v-model="editForm.beam"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
        name="edit-beam"
        translation-key="dock.beam"
        :step="0.1"
      />
      <FormInput
        v-model="editForm.height"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
        name="edit-height"
        translation-key="dock.height"
        :step="0.1"
      />
    </template>

    <template #create>
      <BaseSelect
        v-model="createForm.dockType"
        name="create-dock-type"
        :options="dockTypeOptions"
        :label="t('labels.dock.dockType')"
      />
      <BaseSelect
        v-model="createForm.shipSize"
        name="create-ship-size"
        :options="shipSizeOptions"
        unsorted
        :label="t('labels.dock.shipSize')"
      />
      <FormInput
        v-model="createForm.name"
        name="create-name"
        translation-key="dock.name"
      />
      <FormInput
        v-model="createForm.length"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
        name="create-length"
        translation-key="dock.length"
        :step="0.1"
      />
      <FormInput
        v-model="createForm.beam"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
        name="create-beam"
        translation-key="dock.beam"
        :step="0.1"
      />
      <FormInput
        v-model="createForm.height"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
        name="create-height"
        translation-key="dock.height"
        :step="0.1"
      />
    </template>
  </InlineEditableList>

  <Paginator
    :query-result-ref="data"
    :per-page="perPage"
    :update-per-page="updatePerPage"
  />
</template>

<style lang="scss" scoped>
.docks-editor__dimensions {
  margin-left: 0.5rem;
  opacity: 0.6;
  font-size: 0.875rem;
}
</style>
