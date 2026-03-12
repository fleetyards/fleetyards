<script lang="ts">
export default {
  name: "ModelPaintActionItems",
};
</script>

<script lang="ts" setup>
import {
  type ModelPaint,
  useDestroyModelPaint,
  getListModelPaintsQueryKey,
} from "@/services/fyAdminApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  modelPaint: ModelPaint;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const invalidateModelPaints = () =>
  queryClient.invalidateQueries({
    queryKey: getListModelPaintsQueryKey(),
  });

const destroyMutation = useDestroyModelPaint({
  mutation: {
    onSettled: invalidateModelPaints,
  },
});

const destroy = () => {
  if (!props.modelPaint.id) return;

  displayConfirm({
    text: t("messages.confirm.modelPaint.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.modelPaint.id! });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :size="BtnSizesEnum.SMALL"
    :to="{
      name: 'admin-model-paint-edit',
      params: { id: props.modelPaint.id },
    }"
  >
    <i class="fad fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.delete')"
    :size="BtnSizesEnum.SMALL"
    :variant="BtnVariantsEnum.DANGER"
    @click="destroy"
  >
    <i class="fad fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
