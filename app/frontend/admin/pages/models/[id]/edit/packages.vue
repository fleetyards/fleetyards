<script lang="ts">
export default {
  name: "AdminModelEditPackagesPage",
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
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";
import {
  type ModelExtended,
  type ModelModulePackage,
  type ModelModulePackageInput,
  type ModelModule,
  type ModelModules,
  listModelModules,
  useListModelModulePackages as useListModelModulePackagesQuery,
  useCreateModelModulePackage as useCreateModelModulePackageMutation,
  useUpdateModelModulePackage as useUpdateModelModulePackageMutation,
  useDestroyModelModulePackage as useDestroyModelModulePackageMutation,
  getListModelModulePackagesQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
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

const editableList = ref<{
  editingId: string | null;
  creating: boolean;
  startCreate: () => void;
  finishEdit: () => void;
  finishCreate: () => void;
} | null>(null);

const { data, isLoading } = useListModelModulePackagesQuery({
  perPage: "100",
  q: {
    modelIdEq: props.model.id,
  },
});

const invalidatePackages = async () => {
  await queryClient.invalidateQueries({
    queryKey: getListModelModulePackagesQueryKey(),
  });
};

// Module names helper
const moduleNames = (item: ModelModulePackage) => {
  return item.modules?.map((m) => m.name).join(", ");
};

// Module filter fetch
const fetchModules = async (params: FilterGroupParams<ModelModule>) => {
  const q: Record<string, string> = {};

  if (params.search) {
    q.nameCont = params.search;
  }

  if (params.missing) {
    q.idIn = Array.isArray(params.missing)
      ? (params.missing as string[]).join(",")
      : (params.missing as string);
  }

  return listModelModules({
    page: String(params.page || 1),
    perPage: "50",
    q,
  });
};

const moduleFormatter = (response: ModelModules) => {
  return response.items.map((m) => ({
    label: m.name,
    value: m.id,
  }));
};

// Edit
const editForm = ref<ModelModulePackageInput>({});
const editModuleIds = ref<string[]>([]);

const onStartEdit = (record: ModelModulePackage) => {
  editForm.value = {
    name: record.name,
    description: record.description ?? undefined,
    pledgePrice: record.pledgePrice,
    storeImage: undefined,
  };
  editModuleIds.value = record.modules?.map((m) => m.id) || [];
};

const updateMutation = useUpdateModelModulePackageMutation({
  mutation: {
    onSettled: invalidatePackages,
  },
});

const toggleField = async (
  item: ModelModulePackage,
  field: "active" | "hidden",
) => {
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
    data: {
      ...editForm.value,
      moduleIds: editModuleIds.value,
    },
  });

  editableList.value?.finishEdit();
};

// Delete
const destroyMutation = useDestroyModelModulePackageMutation({
  mutation: {
    onSettled: invalidatePackages,
  },
});

const onDestroy = async (record: ModelModulePackage) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create
const createForm = ref<ModelModulePackageInput>({
  modelId: props.model.id,
});
const createModuleIds = ref<string[]>([]);

const onStartCreate = () => {
  createForm.value = {
    modelId: props.model.id,
  };
  createModuleIds.value = [];
};

const createMutation = useCreateModelModulePackageMutation({
  mutation: {
    onSettled: invalidatePackages,
  },
});

const onSaveCreate = async () => {
  await createMutation.mutateAsync({
    data: {
      ...createForm.value,
      moduleIds: createModuleIds.value,
    },
  });

  editableList.value?.finishCreate();
};
</script>

<template>
  <div class="d-flex align-items-center justify-content-between">
    <Heading>{{ t("headlines.admin.models.edit.packages") }}</Heading>
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
    empty-name="Packages"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as ModelModulePackage[]) || []"
    :confirm-destroy-text="t('messages.confirm.modelModulePackage.destroy')"
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
        class="package-thumbnail"
      />
      <span class="module-name">{{ item.name }}</span>
      <template v-if="item.modules?.length">
        <span class="text-muted">{{ moduleNames(item) }}</span>
      </template>
      <template v-if="item.pledgePrice">
        <span class="text-muted" v-html="toUEC(item.pledgePrice)" />
      </template>
    </template>

    <template #actions="{ item }">
      <Btn
        v-tooltip="t('labels.modelModulePackage.hidden')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="toggleField(item, 'hidden')"
      >
        <i
          class="fad fa-eye-slash"
          :class="item.hidden ? 'text-warning' : 'text-muted'"
        />
      </Btn>
      <Btn
        v-tooltip="t('labels.modelModulePackage.active')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="toggleField(item, 'active')"
      >
        <i
          class="fad fa-ban"
          :class="!item.active ? 'text-warning' : 'text-muted'"
        />
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
          translation-key="modelModulePackage.name"
        />
        <FormInput
          v-model="editForm.pledgePrice"
          name="edit-pledge-price"
          :type="InputTypesEnum.NUMBER"
          translation-key="modelModulePackage.pledgePrice"
        />
      </div>
      <div>
        <FormTextarea
          v-model="editForm.description"
          name="edit-description"
          translation-key="modelModulePackage.description"
        />
        <FilterGroup
          v-model="editModuleIds"
          :label="t('labels.modelModulePackage.modules')"
          :query-fn="fetchModules"
          :query-response-formatter="moduleFormatter"
          name="edit-modules"
          class="full-width"
          :paginated="true"
          :searchable="true"
          :multiple="true"
          :no-label="false"
        />
      </div>
    </template>

    <template #create>
      <div class="row">
        <div class="col-12 col-sm-6">
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
            translation-key="modelModulePackage.name"
          />
        </div>
        <div class="col-12 col-sm-6">
          <FormTextarea
            v-model="createForm.description"
            name="create-description"
            translation-key="modelModulePackage.description"
          />
          <FilterGroup
            v-model="createModuleIds"
            :label="t('labels.modelModulePackage.modules')"
            :query-fn="fetchModules"
            :query-response-formatter="moduleFormatter"
            name="create-modules"
            class="full-width"
            :paginated="true"
            :searchable="true"
            :multiple="true"
            :no-label="false"
          />
          <FormInput
            v-model="createForm.pledgePrice"
            name="create-pledge-price"
            :type="InputTypesEnum.NUMBER"
            translation-key="modelModulePackage.pledgePrice"
          />
        </div>
      </div>
    </template>
  </InlineEditableList>
</template>

<style lang="scss" scoped>
.package-thumbnail {
  width: 80px;
  flex-shrink: 0;
}

.module-name {
  min-width: 150px;
}
</style>
