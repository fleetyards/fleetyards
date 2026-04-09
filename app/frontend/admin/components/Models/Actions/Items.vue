<script lang="ts">
export default {
  name: "ModelActionItems",
};
</script>

<script lang="ts" setup>
import {
  type Model,
  useDestroyModel,
  useReloadOneModel,
  useUseRsiImage,
  getModelsQueryKey,
} from "@/services/fyAdminApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";
import { useImportLoading } from "@/admin/composables/useImportLoading";
import { ImportTypeEnum } from "@/services/fyAdminApi";

type Props = {
  model: Model;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm, displaySuccess } = useAppNotifications();
const queryClient = useQueryClient();

const syncInputMatch = computed(() => ({
  modelId: props.model.id,
  rsiId: props.model.rsiId,
}));

const { isImporting: isImportingSyncing } = useImportLoading(
  [
    ImportTypeEnum.IMPORTS_MODEL_IMPORT,
    ImportTypeEnum.IMPORTS_SC_DATA_MODEL_IMPORT,
  ],
  syncInputMatch,
);

const invalidateModels = () =>
  queryClient.invalidateQueries({
    queryKey: getModelsQueryKey(),
  });

const destroyMutation = useDestroyModel({
  mutation: {
    onSettled: invalidateModels,
  },
});

const reloadOneMutation = useReloadOneModel({
  mutation: {
    onSuccess: () => {
      displaySuccess({
        text: t("messages.model.syncStarted"),
      });
    },
    onSettled: invalidateModels,
  },
});

const isSyncing = computed(
  () => isImportingSyncing.value || reloadOneMutation.isPending.value,
);

const useRsiImageMutation = useUseRsiImage({
  mutation: {
    onSettled: invalidateModels,
  },
});

const sync = () => {
  if (!props.model.id) return;

  displayConfirm({
    text: t("messages.confirm.model.sync"),
    onConfirm: async () => {
      await reloadOneMutation.mutateAsync({ id: props.model.id! });
    },
  });
};

const exchangeStoreImage = () => {
  if (!props.model.id) return;

  displayConfirm({
    text: t("messages.confirm.model.exchangeStoreImage"),
    onConfirm: async () => {
      await useRsiImageMutation.mutateAsync({ id: props.model.id! });
    },
  });
};

const destroy = () => {
  if (!props.model.id) return;

  displayConfirm({
    text: t("messages.confirm.model.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.model.id! });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.models.sync')"
    :size="BtnSizesEnum.SMALL"
    :loading="isSyncing"
    spinner
    @click="sync"
  >
    <i class="fa-duotone fa-rotate" />
    <span v-if="withLabels">{{ t("actions.models.sync") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.models.exchangeStoreImage')"
    :size="BtnSizesEnum.SMALL"
    @click="exchangeStoreImage"
  >
    <i class="fa-duotone fa-arrow-right-arrow-left" />
    <span v-if="withLabels">{{ t("actions.models.exchangeStoreImage") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :size="BtnSizesEnum.SMALL"
    :to="{ name: 'admin-model-edit', params: { id: props.model.id } }"
  >
    <i class="fa-duotone fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.delete')"
    :size="BtnSizesEnum.SMALL"
    :variant="BtnVariantsEnum.DANGER"
    @click="destroy"
  >
    <i class="fa-duotone fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
