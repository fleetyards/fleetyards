<script lang="ts">
export default {
  name: "AdminModelEditSnubCraftsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type ModelExtended,
  type ModelSnubCraft,
  type ModelSnubCraftInput,
  useListModelSnubCrafts as useListModelSnubCraftsQuery,
  useCreateModelSnubCraft as useCreateModelSnubCraftMutation,
  useUpdateModelSnubCraft as useUpdateModelSnubCraftMutation,
  useDestroyModelSnubCraft as useDestroyModelSnubCraftMutation,
  getListModelSnubCraftsQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import ModelFilterGroup from "@/admin/components/base/ModelFilterGroup/index.vue";

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

const snubCraftsQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    modelIdEq: props.model.id,
  },
}));

const snubCraftsQueryKey = computed(() =>
  getListModelSnubCraftsQueryKey(snubCraftsQueryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(snubCraftsQueryKey);

const { data, isLoading } = useListModelSnubCraftsQuery(snubCraftsQueryParams);

const invalidateSnubCrafts = () =>
  queryClient.invalidateQueries({
    queryKey: getListModelSnubCraftsQueryKey(),
  });

// Edit
const editForm = ref<ModelSnubCraftInput>({});

const onStartEdit = (record: ModelSnubCraft) => {
  editForm.value = {
    snubCraftId: record.snubCraftId,
  };
};

const updateMutation = useUpdateModelSnubCraftMutation({
  mutation: {
    onSettled: invalidateSnubCrafts,
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
const destroyMutation = useDestroyModelSnubCraftMutation({
  mutation: {
    onSettled: invalidateSnubCrafts,
  },
});

const onDestroy = async (record: ModelSnubCraft) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create
const createForm = ref<ModelSnubCraftInput>({
  modelId: props.model.id,
});

const onStartCreate = () => {
  createForm.value = {
    modelId: props.model.id,
  };
};

const createMutation = useCreateModelSnubCraftMutation({
  mutation: {
    onSettled: invalidateSnubCrafts,
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
  <div class="flex items-center justify-between">
    <Heading hero>{{ t("headlines.admin.models.edit.snubCrafts") }}</Heading>
    <Btn
      :size="BtnSizesEnum.SMALL"
      :disabled="editableList?.creating"
      @click="editableList?.startCreate()"
    >
      <i class="fa-duotone fa-plus" />
      {{ t("actions.add") }}
    </Btn>
  </div>

  <InlineEditableList
    empty-name="Snub Crafts"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as ModelSnubCraft[]) || []"
    :confirm-destroy-text="t('messages.confirm.modelSnubCraft.destroy')"
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
    @destroy="onDestroy"
  >
    <template #display="{ item }">
      <span v-if="item.snubCraft">{{ item.snubCraft.name }}</span>
    </template>

    <template #edit>
      <ModelFilterGroup
        v-model="editForm.snubCraftId"
        value-attr="id"
        :no-label="false"
        translation-key="modelSnubCraft.snubCraft"
        :multiple="false"
        name="edit-snub-craft-model"
      />
    </template>

    <template #create>
      <ModelFilterGroup
        v-model="createForm.snubCraftId"
        value-attr="id"
        :no-label="false"
        translation-key="modelSnubCraft.snubCraft"
        :multiple="false"
        name="create-snub-craft-model"
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
