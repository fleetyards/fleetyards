<script lang="ts">
export default {
  name: "AdminModelEditPositionsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import {
  type ModelExtended,
  type ModelPosition,
  type ModelPositionInput,
  useListModelPositions as useListModelPositionsQuery,
  useCreateModelPosition as useCreateModelPositionMutation,
  useUpdateModelPosition as useUpdateModelPositionMutation,
  useDestroyModelPosition as useDestroyModelPositionMutation,
  useRegenerateModelPositions as useRegenerateModelPositionsMutation,
  getListModelPositionsQueryKey,
  type FilterOption,
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

const positionTypeOptions: FilterOption[] = [
  { label: "Pilot", value: "pilot" },
  { label: "Copilot", value: "copilot" },
  { label: "Turret Gunner", value: "turret_gunner" },
  { label: "Engineer", value: "engineer" },
  { label: "Gunner", value: "gunner" },
  { label: "Loadmaster", value: "loadmaster" },
  { label: "Passenger", value: "passenger" },
  { label: "Operator", value: "operator" },
  { label: "Custom", value: "custom" },
];

const sourceOptions: FilterOption[] = [
  { label: "SC Data", value: "sc_data" },
  { label: "Curated", value: "curated" },
];

const positionsQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    modelIdEq: props.model.id,
  },
}));

const positionsQueryKey = computed(() =>
  getListModelPositionsQueryKey(positionsQueryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(positionsQueryKey);

const { data, isLoading } = useListModelPositionsQuery(positionsQueryParams);

const invalidatePositions = () =>
  queryClient.invalidateQueries({
    queryKey: getListModelPositionsQueryKey(),
  });

// Edit
const editForm = ref<ModelPositionInput>({});

const onStartEdit = (record: ModelPosition) => {
  editForm.value = {
    name: record.name,
    positionType: record.positionType,
    source: record.source,
    position: record.position,
  };
};

const updateMutation = useUpdateModelPositionMutation({
  mutation: {
    onSettled: invalidatePositions,
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
const destroyMutation = useDestroyModelPositionMutation({
  mutation: {
    onSettled: invalidatePositions,
  },
});

const onDestroy = async (record: ModelPosition) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create
const createForm = ref<ModelPositionInput>({
  modelId: props.model.id,
  source: "curated",
  positionType: "custom",
  position: 0,
});

const onStartCreate = () => {
  createForm.value = {
    modelId: props.model.id,
    source: "curated",
    positionType: "custom",
    position: 0,
  };
};

const createMutation = useCreateModelPositionMutation({
  mutation: {
    onSettled: invalidatePositions,
  },
});

const onSaveCreate = async () => {
  await createMutation.mutateAsync({
    data: createForm.value,
  });

  editableList.value?.finishCreate();
};

// Regenerate
const regenerating = ref(false);

const regenerateMutation = useRegenerateModelPositionsMutation({
  mutation: {
    onSettled: async () => {
      await invalidatePositions();
      regenerating.value = false;
    },
  },
});

const onRegenerate = async () => {
  regenerating.value = true;
  await regenerateMutation.mutateAsync({
    params: { model_id: props.model.id },
  });
};
</script>

<template>
  <div class="flex items-center justify-between">
    <Heading hero>
      {{ t("headlines.admin.models.edit.positions") }}
      <BasePill v-if="model.positionsNeedCuration" uppercase margin-left>
        {{ t("labels.model.needsCuration") }}
      </BasePill>
    </Heading>
    <div class="flex gap-2">
      <Btn
        :size="BtnSizesEnum.SMALL"
        :disabled="regenerating"
        @click="onRegenerate"
      >
        <i class="fa-duotone fa-arrows-rotate" />
        {{ t("actions.regenerate") }}
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :disabled="editableList?.creating"
        @click="editableList?.startCreate()"
      >
        <i class="fa-duotone fa-plus" />
        {{ t("actions.add") }}
      </Btn>
    </div>
  </div>

  <InlineEditableList
    empty-name="Positions"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as ModelPosition[]) || []"
    :confirm-destroy-text="t('messages.confirm.modelPosition.destroy')"
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
    @destroy="onDestroy"
  >
    <template #display="{ item }">
      <div class="position-display">
        <BasePill uppercase margin-right>{{ item.positionType }}</BasePill>
        <BasePill margin-right>{{ item.source }}</BasePill>
        <span class="position-display__name">{{ item.name }}</span>
        <span class="position-display__order text-muted">
          #{{ item.position }}
        </span>
      </div>
    </template>

    <template #edit>
      <div class="position-form">
        <div class="position-form__row">
          <FormInput
            v-model="editForm.name"
            name="edit-name"
            translation-key="modelPosition.name"
          />
          <FormInput
            v-model.number="editForm.position"
            name="edit-position"
            translation-key="modelPosition.position"
            type="number"
          />
        </div>
        <div class="position-form__row">
          <FilterGroup
            v-model="editForm.positionType"
            name="edit-position-type"
            :options="positionTypeOptions"
            :nullable="false"
            translation-key="modelPosition.positionType"
          />
          <FilterGroup
            v-model="editForm.source"
            name="edit-source"
            :options="sourceOptions"
            :nullable="false"
            translation-key="modelPosition.source"
          />
        </div>
      </div>
    </template>

    <template #create>
      <div class="position-form">
        <div class="position-form__row">
          <FormInput
            v-model="createForm.name"
            name="create-name"
            translation-key="modelPosition.name"
          />
          <FormInput
            v-model.number="createForm.position"
            name="create-position"
            translation-key="modelPosition.position"
            type="number"
          />
        </div>
        <div class="position-form__row">
          <FilterGroup
            v-model="createForm.positionType"
            name="create-position-type"
            :options="positionTypeOptions"
            :nullable="false"
            translation-key="modelPosition.positionType"
          />
          <FilterGroup
            v-model="createForm.source"
            name="create-source"
            :options="sourceOptions"
            :nullable="false"
            translation-key="modelPosition.source"
          />
        </div>
      </div>
    </template>
  </InlineEditableList>

  <Paginator
    v-if="data"
    :query-result-ref="data"
    :per-page="perPage"
    :update-per-page="updatePerPage"
  />
</template>

<style lang="scss" scoped>
.position-display {
  display: flex;
  align-items: center;
  gap: 4px;

  &__name {
    font-weight: 500;
  }

  &__order {
    font-size: 0.85em;
  }
}

.position-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;

  &__row {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;

    > * {
      flex: 1;
      min-width: 150px;
    }
  }
}
</style>
