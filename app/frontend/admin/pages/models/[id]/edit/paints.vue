<script lang="ts">
export default {
  name: "AdminModelEditPaintsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
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

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const queryClient = useQueryClient();

const editableList = ref<{
  editingId: string | null;
  creating: boolean;
  startCreate: () => void;
  finishEdit: () => void;
  finishCreate: () => void;
  resetSelected: () => void;
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

// Copy
const paintsById = computed(() => {
  const map = new Map<string, ModelPaint>();
  (data.value?.items || []).forEach((item) => map.set(item.id, item));
  return map;
});

const openCopyModal = (paints: ModelPaint[]) => {
  if (!paints.length) return;

  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/ModelPaints/CopyModal/index.vue"),
    props: {
      paints,
      sourceModelId: props.model.id,
    },
  });
};

const copyPaint = (item: ModelPaint) => {
  openCopyModal([item]);
};

const bulkCopy = (selectedIds: string[]) => {
  const paints = selectedIds
    .map((id) => paintsById.value.get(id))
    .filter((paint): paint is ModelPaint => !!paint);

  openCopyModal(paints);
  editableList.value?.resetSelected();
};
</script>

<template>
  <div class="flex items-center justify-between">
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
    selectable
    :items="(data?.items as ModelPaint[]) || []"
    :confirm-destroy-text="t('messages.confirm.modelPaint.destroy')"
    @start-edit="onStartEdit"
    @save-edit="onSaveEdit"
    @start-create="onStartCreate"
    @save-create="onSaveCreate"
    @destroy="onDestroy"
  >
    <template #selected-actions="{ selected }">
      <Btn :size="BtnSizesEnum.SMALL" @click="bulkCopy(selected)">
        <i class="fa-duotone fa-copy" />
        {{ t("actions.copy") }}
      </Btn>
    </template>
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

    <template #actions="{ item, mobile }">
      <Btn
        v-tooltip="t('labels.modelPaint.hidden')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="toggleField(item, 'hidden')"
      >
        <i
          class="fa-duotone fa-eye"
          :class="!item.hidden ? '' : 'text-muted'"
        />
        <span v-if="mobile">{{ t("labels.modelPaint.hidden") }}</span>
      </Btn>
      <Btn
        v-tooltip="t('labels.modelPaint.active')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="toggleField(item, 'active')"
      >
        <i
          class="fa-duotone fa-circle-check"
          :class="item.active ? 'text-success' : 'text-muted'"
        />
        <span v-if="mobile">{{ t("labels.modelPaint.active") }}</span>
      </Btn>
      <Btn
        v-tooltip="!mobile && t('actions.copy')"
        :size="BtnSizesEnum.SMALL"
        @click="copyPaint(item)"
      >
        <i class="fa-duotone fa-copy" />
        <span v-if="mobile">{{ t("actions.copy") }}</span>
      </Btn>
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
