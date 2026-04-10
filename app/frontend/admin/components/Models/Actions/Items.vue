<script lang="ts">
export default {
  name: "ModelActionItems",
};
</script>

<script lang="ts" setup>
import {
  type Model,
  useDestroyModel,
  useReloadOneModelMatrix,
  useReloadOneModelScData,
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

const matrixInputMatch = computed(() => ({
  modelId: props.model.id,
  rsiId: props.model.rsiId,
}));

const scDataInputMatch = computed(() => ({
  modelId: props.model.id,
}));

const { isImporting: isImportingMatrix } = useImportLoading(
  [ImportTypeEnum.IMPORTS_MODEL_IMPORT],
  matrixInputMatch,
);

const { isImporting: isImportingScData } = useImportLoading(
  [ImportTypeEnum.IMPORTS_SC_DATA_MODEL_IMPORT],
  scDataInputMatch,
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

const reloadMatrixMutation = useReloadOneModelMatrix({
  mutation: {
    onSuccess: () => {
      displaySuccess({
        text: t("messages.model.syncMatrixStarted"),
      });
    },
    onSettled: invalidateModels,
  },
});

const reloadScDataMutation = useReloadOneModelScData({
  mutation: {
    onSuccess: () => {
      displaySuccess({
        text: t("messages.model.syncScDataStarted"),
      });
    },
    onSettled: invalidateModels,
  },
});

const isSyncingMatrix = computed(
  () => isImportingMatrix.value || reloadMatrixMutation.isPending.value,
);

const isSyncingScData = computed(
  () => isImportingScData.value || reloadScDataMutation.isPending.value,
);

const useRsiImageMutation = useUseRsiImage({
  mutation: {
    onSettled: invalidateModels,
  },
});

const syncMatrix = () => {
  if (!props.model.id) return;

  displayConfirm({
    text: t("messages.confirm.model.syncMatrix"),
    onConfirm: async () => {
      await reloadMatrixMutation.mutateAsync({ id: props.model.id! });
    },
  });
};

const syncScData = () => {
  if (!props.model.id) return;

  displayConfirm({
    text: t("messages.confirm.model.syncScData"),
    onConfirm: async () => {
      await reloadScDataMutation.mutateAsync({ id: props.model.id! });
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
    v-tooltip="!withLabels && t('actions.models.syncMatrix')"
    :size="BtnSizesEnum.SMALL"
    :loading="isSyncingMatrix"
    spinner
    @click="syncMatrix"
  >
    <i class="fa-duotone fa-rotate" />
    <span v-if="withLabels">{{ t("actions.models.syncMatrix") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.models.syncScData')"
    :size="BtnSizesEnum.SMALL"
    :loading="isSyncingScData"
    spinner
    @click="syncScData"
  >
    <i class="fa-duotone fa-database" />
    <span v-if="withLabels">{{ t("actions.models.syncScData") }}</span>
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
