<script lang="ts">
export default {
  name: "AdminModelEditUpgradesPage",
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
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import {
  type ModelExtended,
  type ModelUpgrade,
  type ModelUpgradeInput,
  useListModelUpgrades as useListModelUpgradesQuery,
  useCreateModelUpgrade as useCreateModelUpgradeMutation,
  useUpdateModelUpgrade as useUpdateModelUpgradeMutation,
  useDestroyModelUpgrade as useDestroyModelUpgradeMutation,
  useUnlinkModelUpgrade as useUnlinkModelUpgradeMutation,
  getListModelUpgradesQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
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

const upgradesQueryParams = computed(() => ({
  page: page.value,
  perPage: perPage.value,
  q: {
    upgradeKitsModelIdEq: props.model.id,
  },
}));

const upgradesQueryKey = computed(() =>
  getListModelUpgradesQueryKey(upgradesQueryParams.value),
);

const { perPage, page, updatePerPage } = usePagination(upgradesQueryKey);

const { data, isLoading } = useListModelUpgradesQuery(upgradesQueryParams);

const invalidateUpgrades = () =>
  queryClient.invalidateQueries({
    queryKey: getListModelUpgradesQueryKey(),
  });

// Edit
const editForm = ref<ModelUpgradeInput>({});

const onStartEdit = (record: ModelUpgrade) => {
  editForm.value = {
    name: record.name,
    description: record.description ?? undefined,
    pledgePrice: record.pledgePrice,
    storeImage: undefined,
  };
};

const updateMutation = useUpdateModelUpgradeMutation({
  mutation: {
    onSettled: invalidateUpgrades,
  },
});

const toggleField = async (item: ModelUpgrade, field: "active" | "hidden") => {
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
const destroyMutation = useDestroyModelUpgradeMutation({
  mutation: {
    onSettled: invalidateUpgrades,
  },
});

const onDestroy = async (record: ModelUpgrade) => {
  await destroyMutation.mutateAsync({ id: record.id });
};

// Create
const createForm = ref<ModelUpgradeInput>({
  modelId: props.model.id,
});

const onStartCreate = () => {
  createForm.value = {
    modelId: props.model.id,
  };
};

const createMutation = useCreateModelUpgradeMutation({
  mutation: {
    onSettled: invalidateUpgrades,
  },
});

const onSaveCreate = async () => {
  await createMutation.mutateAsync({
    data: createForm.value,
  });

  editableList.value?.finishCreate();
};

// Link existing upgrade via modal
const openLinkModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/admin/components/Models/LinkUpgradeModal/index.vue"),
    props: {
      modelId: props.model.id,
    },
  });
};

// Unlink
const unlinkMutation = useUnlinkModelUpgradeMutation({
  mutation: {
    onSettled: invalidateUpgrades,
  },
});

const onUnlink = (record: ModelUpgrade) => {
  displayConfirm({
    text: t("messages.confirm.modelUpgrade.unlink"),
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
  <div class="d-flex align-items-center justify-content-between">
    <Heading hero>{{ t("headlines.admin.models.edit.upgrades") }}</Heading>
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
    stacked
    empty-name="Upgrades"
    :loading="isLoading"
    ref="editableList"
    :items="(data?.items as ModelUpgrade[]) || []"
    :confirm-destroy-text="t('messages.confirm.modelUpgrade.destroy')"
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
        class="upgrade-thumbnail"
      />
      <span>{{ item.name }}</span>
      <template v-if="item.pledgePrice">
        <span class="text-muted" v-html="toUEC(item.pledgePrice)" />
      </template>
    </template>

    <template #actions="{ item }">
      <Btn
        v-tooltip="t('actions.unlink')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="onUnlink(item)"
      >
        <i class="fa-duotone fa-unlink text-muted" />
      </Btn>
      <Btn
        v-tooltip="t('labels.modelUpgrade.hidden')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="toggleField(item, 'hidden')"
      >
        <i
          class="fa-duotone fa-eye-slash"
          :class="item.hidden ? 'text-warning' : 'text-muted'"
        />
      </Btn>
      <Btn
        v-tooltip="t('labels.modelUpgrade.active')"
        :size="BtnSizesEnum.SMALL"
        :variant="BtnVariantsEnum.TRANSPARENT"
        @click="toggleField(item, 'active')"
      >
        <i
          class="fa-duotone fa-ban"
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
        <FormTextarea
          v-model="editForm.description"
          name="edit-description"
          translation-key="modelUpgrade.description"
        />
      </div>
      <div>
        <FormInput
          v-model="editForm.name"
          name="edit-name"
          translation-key="modelUpgrade.name"
        />
        <FormInput
          v-model="editForm.pledgePrice"
          name="edit-pledge-price"
          :type="InputTypesEnum.NUMBER"
          translation-key="modelUpgrade.pledgePrice"
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
          translation-key="modelUpgrade.name"
        />
      </div>
      <div>
        <FormTextarea
          v-model="createForm.description"
          name="create-description"
          translation-key="modelUpgrade.description"
        />
        <FormInput
          v-model="createForm.pledgePrice"
          name="create-pledge-price"
          :type="InputTypesEnum.NUMBER"
          translation-key="modelUpgrade.pledgePrice"
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
.upgrade-thumbnail {
  width: 80px;
  flex-shrink: 0;
}
</style>
