<script lang="ts">
export default {
  name: "AdminModelEditPaintsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import Toggle from "@/shared/components/base/Toggle/index.vue";
import {
  type ModelExtended,
  type ModelPaint,
  type ModelPaintInput,
  useListModelPaints as useListModelPaintsQuery,
  useCreateModelPaint as useCreateModelPaintMutation,
  useUpdateModelPaint as useUpdateModelPaintMutation,
  useDestroyModelPaint as useDestroyModelPaintMutation,
  getListModelPaintsQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
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

const paintsQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    modelIdEq: props.model.id,
  },
}));

const paintsQueryKey = computed(() =>
  getListModelPaintsQueryKey(paintsQueryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(paintsQueryKey);

const { data, isLoading } = useListModelPaintsQuery(paintsQueryParams);

const invalidatePaints = () =>
  queryClient.invalidateQueries({
    queryKey: getListModelPaintsQueryKey(),
  });

// Edit
const editForm = ref<ModelPaintInput>({});

const onStartEdit = (record: ModelPaint) => {
  editForm.value = {
    name: record.name,
  };
};

const updateMutation = useUpdateModelPaintMutation({
  mutation: {
    onSettled: invalidatePaints,
  },
});

const toggleField = async (item: ModelPaint, field: "active" | "hidden") => {
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
const destroyMutation = useDestroyModelPaintMutation({
  mutation: {
    onSettled: invalidatePaints,
  },
});

const onDestroy = async (record: ModelPaint) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create
const createForm = ref<ModelPaintInput>({
  modelId: props.model.id,
});

const onStartCreate = () => {
  createForm.value = {
    modelId: props.model.id,
  };
};

const createMutation = useCreateModelPaintMutation({
  mutation: {
    onSettled: invalidatePaints,
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
    <Heading hero>{{ t("headlines.admin.models.edit.paints") }}</Heading>
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
    empty-name="Paints"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as ModelPaint[]) || []"
    :confirm-destroy-text="t('messages.confirm.modelPaint.destroy')"
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
    @destroy="onDestroy"
  >
    <template #display="{ item }">
      <LazyImage
        v-if="item.media?.storeImage"
        :src="item.media.storeImage.smallUrl"
        :variant="LazyImageVariantsEnum.WIDE_SMALL"
        :alt="item.name"
        class="paint-thumbnail"
      />
      <span>{{ item.name }}</span>
    </template>

    <template #actions="{ item }">
      <Toggle
        v-tooltip="t('labels.modelPaint.hidden')"
        :active="!item.hidden"
        @toggle="toggleField(item, 'hidden')"
      />
      <Toggle
        v-tooltip="t('labels.modelPaint.active')"
        :active="item.active"
        @toggle="toggleField(item, 'active')"
      />
    </template>

    <template #edit="{ item }">
      <FormFileInput
        v-model="editForm.storeImage"
        :file="item.media?.storeImage"
        name="edit-store-image"
        translation-key="model.storeImage"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />
      <FormInput
        v-model="editForm.name"
        name="edit-name"
        translation-key="name"
      />
    </template>

    <template #create>
      <FormFileInput
        v-model="createForm.storeImage"
        name="create-store-image"
        translation-key="model.storeImage"
        :allowed-types="AllowedFileTypes.IMAGE"
        small
      />
      <FormInput
        v-model="createForm.name"
        name="create-name"
        translation-key="name"
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

<style lang="scss" scoped>
.paint-thumbnail {
  width: 80px;
  flex-shrink: 0;
}
</style>
