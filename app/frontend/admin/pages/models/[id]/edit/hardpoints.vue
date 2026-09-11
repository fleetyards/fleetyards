<script lang="ts">
export default {
  name: "AdminModelEditHardpointsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
// Registered globally as `Select`, so `<BaseSelect>` resolves to nothing
// without this and every dropdown below renders as an empty comment.
import BaseSelect from "@/shared/components/base/Select/index.vue";
import {
  type AdminHardpoint,
  type AdminHardpointInput,
  type ModelExtended,
  type FilterOption,
  HardpointGroupEnum,
  HardpointCategoryEnum,
  useListHardpoints as useListHardpointsQuery,
  useCreateHardpoint as useCreateHardpointMutation,
  useUpdateHardpoint as useUpdateHardpointMutation,
  useDestroyHardpoint as useDestroyHardpointMutation,
  getListHardpointsQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t, tExists } = useI18n();
const queryClient = useQueryClient();

const editableList = ref<{
  editingId: string | null;
  creating: boolean;
  startCreate: () => void;
  finishEdit: () => void;
  finishCreate: () => void;
} | null>(null);

// The enum values already have human labels in every locale under
// `labels.hardpoint.groups` and `.categories`, so the options are built from
// them rather than restating 48 strings. The maps do not cover every value --
// `unknown` among them -- so a missing one falls back to the raw value rather
// than rendering a key path.
const optionsFrom = (
  values: Record<string, string>,
  scope: "groups" | "categories",
): FilterOption[] =>
  Object.values(values).map((value) => {
    const key = `labels.hardpoint.${scope}.${value}`;

    return { label: tExists(key) ? t(key) : value, value };
  });

const groupOptions = optionsFrom(HardpointGroupEnum, "groups");
const categoryOptions = optionsFrom(HardpointCategoryEnum, "categories");

// Two lists rather than one with the buttons greyed out, because the halves
// have different owners and that is the thing worth showing. The loader rewrites
// the game-file rows on every load, so an edit there would last until the next
// one; the matrix half is curated and `persist_loadout` never touches it.
//
// Top-level slots only -- the nested ones come inside their parent, because a
// loadout is a tree.
const paramsFor = (source: "game_files" | "ship_matrix") => ({
  q: {
    parentIdEq: props.model.id,
    parentTypeEq: "Model",
    sourceEq: source,
  },
  perPage: 200,
});

const loaderParams = computed(() => paramsFor("game_files"));
const curatedParams = computed(() => paramsFor("ship_matrix"));

const { data: loaderData, isLoading: loaderLoading } =
  useListHardpointsQuery(loaderParams);
const { data: curatedData, isLoading: curatedLoading } =
  useListHardpointsQuery(curatedParams);

const invalidateHardpoints = () =>
  queryClient.invalidateQueries({ queryKey: getListHardpointsQueryKey() });

const sizeRange = (hardpoint: AdminHardpoint) => {
  const { minSize, maxSize } = hardpoint;

  if (minSize == null && maxSize == null) return null;
  if (minSize === maxSize) return `${minSize}`;

  return `${minSize ?? "?"}–${maxSize ?? "?"}`;
};

// Edit
const editForm = ref<AdminHardpointInput>({});

const onStartEdit = (record: AdminHardpoint) => {
  editForm.value = {
    scName: record.name,
    group: record.group,
    category: record.category,
    minSize: record.minSize,
    maxSize: record.maxSize,
    details: record.details,
  };
};

const updateMutation = useUpdateHardpointMutation({
  mutation: { onSettled: invalidateHardpoints },
});

const onSaveEdit = async () => {
  const id = editableList.value?.editingId;
  if (!id) return;

  await updateMutation.mutateAsync({ id, data: editForm.value });

  editableList.value?.finishEdit();
};

// Delete
const destroyMutation = useDestroyHardpointMutation({
  mutation: { onSettled: invalidateHardpoints },
});

const onDestroy = async (record: AdminHardpoint) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create. `source` is not sent: the endpoint always creates a curated slot, so
// there is no way to ask for one the next load would rewrite.
const blankCreateForm = (): AdminHardpointInput => ({
  parentId: props.model.id,
  parentType: "Model",
  group: "other",
  category: "unknown",
});

const createForm = ref<AdminHardpointInput>(blankCreateForm());

const onStartCreate = () => {
  createForm.value = blankCreateForm();
};

const createMutation = useCreateHardpointMutation({
  mutation: { onSettled: invalidateHardpoints },
});

const onSaveCreate = async () => {
  await createMutation.mutateAsync({ data: createForm.value });

  editableList.value?.finishCreate();
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.models.edit.hardpoints") }}</Heading>

  <!-- The loader's half. Read only, and the pill says why rather than leaving
       an admin to wonder where the buttons went. -->
  <div class="flex items-center gap-2 mb-4 mt-6">
    <Heading>{{ t("labels.hardpoint.source") }}</Heading>
    <BasePill uppercase>game_files</BasePill>
  </div>

  <InlineEditableList
    empty-name="Hardpoints"
    hide-edit
    hide-destroy
    :loading="loaderLoading"
    :items="(loaderData?.items as AdminHardpoint[]) || []"
  >
    <template #display="{ item }">
      <div class="flex flex-wrap items-center gap-2">
        <BasePill v-if="item.retired" uppercase>
          {{ t("labels.model.inGame") }}
        </BasePill>
        <BasePill uppercase>{{ item.group }}</BasePill>
        <BasePill>{{ item.category }}</BasePill>
        <span>{{ item.name }}</span>
        <span v-if="sizeRange(item)" class="text-muted">
          {{ t("labels.hardpoint.size") }} {{ sizeRange(item) }}
        </span>
        <span v-if="item.component" class="text-muted">
          {{ item.component.name }}
        </span>
        <span v-if="item.hardpoints?.length" class="text-muted">
          +{{ item.hardpoints.length }}
        </span>
      </div>
    </template>
  </InlineEditableList>

  <!-- The curated half. -->
  <div class="flex items-center justify-between mb-4 mt-8">
    <div class="flex items-center gap-2">
      <Heading>{{ t("labels.hardpoint.source") }}</Heading>
      <BasePill uppercase>ship_matrix</BasePill>
    </div>
    <Btn
      :disabled="editableList?.creating"
      @click="editableList?.startCreate()"
    >
      <i class="fa-duotone fa-plus" />
      {{ t("actions.add") }}
    </Btn>
  </div>

  <InlineEditableList
    empty-name="Hardpoints"
    ref="editableList"
    :loading="curatedLoading"
    :items="(curatedData?.items as AdminHardpoint[]) || []"
    :confirm-destroy-text="t('messages.confirm.hardpoint.destroy')"
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
    @destroy="onDestroy"
  >
    <template #display="{ item }">
      <div class="flex flex-wrap items-center gap-2">
        <BasePill uppercase>{{ item.group }}</BasePill>
        <BasePill>{{ item.category }}</BasePill>
        <span>{{ item.name }}</span>
        <span v-if="sizeRange(item)" class="text-muted">
          {{ t("labels.hardpoint.size") }} {{ sizeRange(item) }}
        </span>
      </div>
    </template>

    <template #edit>
      <div class="flex flex-col gap-2">
        <FormInput
          v-model="editForm.scName"
          name="edit-sc-name"
          translation-key="hardpoint.name"
        />
        <div class="flex gap-2">
          <BaseSelect
            v-model="editForm.group"
            name="edit-group"
            :options="groupOptions"
            :nullable="false"
            translation-key="hardpoint.group"
          />
          <BaseSelect
            v-model="editForm.category"
            name="edit-category"
            :options="categoryOptions"
            :nullable="false"
            translation-key="hardpoint.category"
          />
        </div>
        <div class="flex gap-2">
          <FormInput
            v-model.number="editForm.minSize"
            name="edit-min-size"
            translation-key="hardpoint.size"
            type="number"
          />
          <FormInput
            v-model.number="editForm.maxSize"
            name="edit-max-size"
            translation-key="hardpoint.size"
            type="number"
          />
        </div>
        <FormInput
          v-model="editForm.details"
          name="edit-details"
          translation-key="hardpoint.details"
        />
      </div>
    </template>

    <template #create>
      <div class="flex flex-col gap-2">
        <FormInput
          v-model="createForm.scName"
          name="create-sc-name"
          translation-key="hardpoint.name"
        />
        <div class="flex gap-2">
          <BaseSelect
            v-model="createForm.group"
            name="create-group"
            :options="groupOptions"
            :nullable="false"
            translation-key="hardpoint.group"
          />
          <BaseSelect
            v-model="createForm.category"
            name="create-category"
            :options="categoryOptions"
            :nullable="false"
            translation-key="hardpoint.category"
          />
        </div>
        <div class="flex gap-2">
          <FormInput
            v-model.number="createForm.minSize"
            name="create-min-size"
            translation-key="hardpoint.size"
            type="number"
          />
          <FormInput
            v-model.number="createForm.maxSize"
            name="create-max-size"
            translation-key="hardpoint.size"
            type="number"
          />
        </div>
      </div>
    </template>
  </InlineEditableList>
</template>
