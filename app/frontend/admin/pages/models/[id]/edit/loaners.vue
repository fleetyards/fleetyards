<script lang="ts">
export default {
  name: "AdminModelEditLoanersPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import {
  type ModelExtended,
  type ModelLoaner,
  type ModelLoanerInput,
  useListModelLoaners as useListModelLoanersQuery,
  useCreateModelLoaner as useCreateModelLoanerMutation,
  useUpdateModelLoaner as useUpdateModelLoanerMutation,
  useDestroyModelLoaner as useDestroyModelLoanerMutation,
  getListModelLoanersQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import ModelFilterGroup from "@/admin/components/base/ModelFilterGroup/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

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

const loanersQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    modelIdEq: props.model.id,
  },
}));

const loanersQueryKey = computed(() =>
  getListModelLoanersQueryKey(loanersQueryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(loanersQueryKey);

const { data, isLoading } = useListModelLoanersQuery(loanersQueryParams);

const invalidateLoaners = () =>
  queryClient.invalidateQueries({
    queryKey: getListModelLoanersQueryKey(),
  });

// Edit
const editForm = ref<ModelLoanerInput>({});

const onStartEdit = (record: ModelLoaner) => {
  editForm.value = {
    loanerModelId: record.loanerModelId,
  };
};

const updateMutation = useUpdateModelLoanerMutation({
  mutation: {
    onSettled: invalidateLoaners,
  },
});

const toggleField = async (item: ModelLoaner, field: "hidden") => {
  await updateMutation.mutateAsync({
    id: item.id,
    data: { [field]: !item[field] },
  });
};

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
const destroyMutation = useDestroyModelLoanerMutation({
  mutation: {
    onSettled: invalidateLoaners,
  },
});

const onDestroy = async (record: ModelLoaner) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create
const createForm = ref<ModelLoanerInput>({
  modelId: props.model.id,
});

const onStartCreate = () => {
  createForm.value = {
    modelId: props.model.id,
  };
};

const createMutation = useCreateModelLoanerMutation({
  mutation: {
    onSettled: invalidateLoaners,
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
    <Heading hero>{{ t("headlines.admin.models.edit.loaners") }}</Heading>
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
    empty-name="Loaners"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as ModelLoaner[]) || []"
    :confirm-destroy-text="t('messages.confirm.modelLoaner.destroy')"
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
    @destroy="onDestroy"
  >
    <template #display="{ item }">
      <span v-if="item.loanerModel">{{ item.loanerModel.name }}</span>
    </template>

    <template #actions="{ item }">
      <Btn
        v-tooltip="t('labels.modelLoaner.hidden')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="toggleField(item, 'hidden')"
      >
        <i
          class="fa-duotone fa-eye-slash"
          :class="item.hidden ? 'text-warning' : 'text-muted'"
        />
      </Btn>
    </template>

    <template #edit>
      <ModelFilterGroup
        v-model="editForm.loanerModelId"
        value-attr="id"
        :no-label="false"
        translation-key="modelLoaner.loanerModel"
        :multiple="false"
        name="edit-loaner-model"
      />
    </template>

    <template #create>
      <ModelFilterGroup
        v-model="createForm.loanerModelId"
        value-attr="id"
        :no-label="false"
        translation-key="modelLoaner.loanerModel"
        :multiple="false"
        name="create-loaner-model"
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
