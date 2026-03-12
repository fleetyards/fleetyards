<script lang="ts">
export default {
  name: "HardpointLoadouts",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import {
  type ModelHardpoint,
  type ModelHardpointLoadout,
  useCreateModelHardpointLoadout as useCreateLoadoutMutation,
  useUpdateModelHardpointLoadout as useUpdateLoadoutMutation,
  useDestroyModelHardpointLoadout as useDestroyLoadoutMutation,
  getListModelHardpointsQueryKey,
} from "@/services/fyAdminApi";
import type { ModelHardpointLoadoutInput } from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

type Props = {
  hardpoint: ModelHardpoint;
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

const loadouts = computed(
  () => (props.hardpoint.loadouts as ModelHardpointLoadout[]) || [],
);

const invalidateHardpoints = () =>
  queryClient.invalidateQueries({
    queryKey: getListModelHardpointsQueryKey(),
  });

// Edit
const editForm = ref<ModelHardpointLoadoutInput>({});

const onStartEdit = (record: ModelHardpointLoadout) => {
  editForm.value = {
    name: record.name,
  };
};

const updateMutation = useUpdateLoadoutMutation({
  mutation: {
    onSettled: invalidateHardpoints,
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
const destroyMutation = useDestroyLoadoutMutation({
  mutation: {
    onSettled: invalidateHardpoints,
  },
});

const onDestroy = async (record: ModelHardpointLoadout) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create
const createForm = ref<ModelHardpointLoadoutInput>({
  modelHardpointId: props.hardpoint.id,
});

const onStartCreate = () => {
  createForm.value = {
    modelHardpointId: props.hardpoint.id,
  };
};

const createMutation = useCreateLoadoutMutation({
  mutation: {
    onSettled: invalidateHardpoints,
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
  <div class="hardpoint-loadouts">
    <div class="d-flex align-items-center justify-content-between">
      <h4 class="hardpoint-loadouts__title">
        {{ t("labels.admin.modelHardpoint.loadouts") }}
      </h4>
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
      empty-name="Loadouts"
      ref="editableList"
      :items="loadouts"
      :confirm-destroy-text="
        t('messages.confirm.modelHardpointLoadout.destroy')
      "
      @start-edit="onStartEdit"
      @save-edit="onSaveEdit"
      @start-create="onStartCreate"
      @save-create="onSaveCreate"
      @destroy="onDestroy"
    >
      <template #display="{ item }">
        <span>{{ item.name }}</span>
        <span v-if="item.component" class="text-muted ms-2">
          ({{ item.component.name }})
        </span>
      </template>

      <template #edit>
        <FormInput
          v-model="editForm.name"
          name="edit-loadout-name"
          translation-key="modelHardpointLoadout.name"
        />
      </template>

      <template #create>
        <FormInput
          v-model="createForm.name"
          name="create-loadout-name"
          translation-key="modelHardpointLoadout.name"
        />
      </template>
    </InlineEditableList>
  </div>
</template>

<style lang="scss" scoped>
.hardpoint-loadouts {
  padding: 12px 16px;
  margin: 0 0 8px;
  background: rgba(255, 255, 255, 0.03);
  border-left: 3px solid var(--primary, #007bff);
  border-radius: 0 4px 4px 0;

  &__title {
    margin: 0 0 8px;
    font-size: 0.9em;
    font-weight: 600;
  }
}
</style>
