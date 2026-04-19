<script lang="ts">
export default {
  name: "AdminModelEditModulesPage",
};
</script>

<script lang="ts" setup>
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import {
  type ModelExtended,
  type ModelModule,
  type ModelModuleInput,
  useListModelModules as useListModelModulesQuery,
  useCreateModelModule as useCreateModelModuleMutation,
  useUpdateModelModule as useUpdateModelModuleMutation,
  useDestroyModelModule as useDestroyModelModuleMutation,
  useUnlinkModelModule as useUnlinkModelModuleMutation,
  getListModelModulesQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import ManufacturerFilterGroup from "@/admin/components/base/ManufacturerFilterGroup/index.vue";
import ProductionStatusFilterGroup from "@/admin/components/base/ProductionStatusFilterGroup/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t, toUEC } = useI18n();
const queryClient = useQueryClient();
const comlink = useComlink();
const { displayConfirm } = useAppNotifications();

const editableList = ref<{
  editingId: string | null;
  creating: boolean;
  startCreate: () => void;
  finishEdit: () => void;
  finishCreate: () => void;
} | null>(null);

const modulesQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    moduleHardpointsModelIdEq: props.model.id,
  },
}));

const modulesQueryKey = computed(() =>
  getListModelModulesQueryKey(modulesQueryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(modulesQueryKey);

const { data, isLoading } = useListModelModulesQuery(modulesQueryParams);

const invalidateModules = () =>
  queryClient.invalidateQueries({
    queryKey: getListModelModulesQueryKey(),
  });

// Edit
const editForm = ref<ModelModuleInput>({});

const onStartEdit = (record: ModelModule) => {
  editForm.value = {
    name: record.name,
    description: record.description,
    manufacturerId: record.manufacturer?.id,
    pledgePrice: record.pledgePrice,
    productionStatus: record.productionStatus,
    scKey: record.scKey,
    storeImage: undefined,
  };
};

const updateMutation = useUpdateModelModuleMutation({
  mutation: {
    onSettled: invalidateModules,
  },
});

const toggleField = async (item: ModelModule, field: "active" | "hidden") => {
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
const destroyMutation = useDestroyModelModuleMutation({
  mutation: {
    onSettled: invalidateModules,
  },
});

const onDestroy = async (record: ModelModule) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create
const createForm = ref<ModelModuleInput>({
  modelId: props.model.id,
});

const onStartCreate = () => {
  createForm.value = {
    modelId: props.model.id,
  };
};

const createMutation = useCreateModelModuleMutation({
  mutation: {
    onSettled: invalidateModules,
  },
});

const onSaveCreate = async () => {
  await createMutation.mutateAsync({
    data: createForm.value,
  });

  editableList.value?.finishCreate();
};

// Link existing module via modal
const openLinkModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/Models/LinkModuleModal/index.vue"),
    props: {
      modelId: props.model.id,
    },
  });
};

// Unlink
const unlinkMutation = useUnlinkModelModuleMutation({
  mutation: {
    onSettled: invalidateModules,
  },
});

const onUnlink = (record: ModelModule) => {
  displayConfirm({
    text: t("messages.confirm.modelModule.unlink"),
    onConfirm: async () => {
      await unlinkMutation.mutateAsync({
        id: record.id,
        data: { modelId: props.model.id },
      });
    },
  });
};
</script>

<template>
  <div class="flex items-center justify-between">
    <Heading hero>{{ t("headlines.admin.models.edit.modules") }}</Heading>
    <BtnGroup>
      <Btn
        :size="BtnSizesEnum.SMALL"
        :disabled="editableList?.creating"
        @click="editableList?.startCreate()"
      >
        <i class="fa-duotone fa-plus" />
        {{ t("actions.add") }}
      </Btn>
      <Btn :size="BtnSizesEnum.SMALL" @click="openLinkModal">
        <i class="fa-duotone fa-link" />
        {{ t("actions.linkExisting") }}
      </Btn>
    </BtnGroup>
  </div>

  <InlineEditableList
    empty-name="Modules"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as ModelModule[]) || []"
    :confirm-destroy-text="t('messages.confirm.modelModule.destroy')"
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
        class="module-thumbnail"
      />
      <span>{{ item.name }}</span>
      <template v-if="item.manufacturer">
        <span class="text-muted">{{ item.manufacturer.name }}</span>
      </template>
      <template v-if="item.scKey">
        <span class="text-muted">{{ item.scKey }}</span>
      </template>
      <template v-if="item.pledgePrice">
        <span class="text-muted" v-html="toUEC(item.pledgePrice)" />
      </template>
    </template>

    <template #actions="{ item, mobile }">
      <Btn
        v-tooltip="t('labels.modelModule.hidden')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="toggleField(item, 'hidden')"
      >
        <i
          class="fa-duotone fa-eye"
          :class="!item.hidden ? '' : 'text-muted'"
        />
        <span v-if="mobile">{{ t("labels.modelModule.hidden") }}</span>
      </Btn>
      <Btn
        v-tooltip="t('labels.modelModule.active')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="toggleField(item, 'active')"
      >
        <i
          class="fa-duotone fa-circle-check"
          :class="item.active ? 'text-success' : 'text-muted'"
        />
        <span v-if="mobile">{{ t("labels.modelModule.active") }}</span>
      </Btn>
      <Btn
        v-tooltip="t('actions.unlink')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="onUnlink(item)"
      >
        <i class="fa-duotone fa-unlink text-muted" />
        <span v-if="mobile">{{ t("actions.unlink") }}</span>
      </Btn>
    </template>

    <template #edit="{ item }">
      <div>
        <FormFileInput
          v-model="editForm.storeImage"
          :file="item.media?.storeImage"
          name="edit-store-image"
          translation-key="model.storeImage"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
          small
        />
        <FormInput
          v-model="editForm.name"
          name="edit-name"
          translation-key="modelModule.name"
        />
      </div>
      <div>
        <ManufacturerFilterGroup
          v-model="editForm.manufacturerId"
          name="edit-manufacturer"
          :multiple="false"
          :no-label="false"
          value-attr="id"
        />
        <ProductionStatusFilterGroup
          v-model="editForm.productionStatus"
          name="edit-production-status"
          :no-label="false"
          :multiple="false"
        />
        <FormInput
          v-model="editForm.pledgePrice"
          name="edit-pledge-price"
          :type="InputTypesEnum.NUMBER"
          translation-key="modelModule.pledgePrice"
        />
        <FormInput
          v-model="editForm.scKey"
          name="edit-sc-key"
          translation-key="modelModule.scKey"
        />
      </div>
    </template>

    <template #create>
      <div>
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
          translation-key="modelModule.name"
        />
      </div>
      <div>
        <ManufacturerFilterGroup
          v-model="createForm.manufacturerId"
          name="create-manufacturer"
          :multiple="false"
          :no-label="false"
          value-attr="id"
        />
        <ProductionStatusFilterGroup
          v-model="createForm.productionStatus"
          name="create-production-status"
          :multiple="false"
          :no-label="false"
        />
        <FormInput
          v-model="createForm.pledgePrice"
          name="create-pledge-price"
          :type="InputTypesEnum.NUMBER"
          translation-key="modelModule.pledgePrice"
        />
        <FormInput
          v-model="createForm.scKey"
          name="create-sc-key"
          translation-key="modelModule.scKey"
        />
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
.module-thumbnail {
  width: 80px;
  flex-shrink: 0;
}
</style>
