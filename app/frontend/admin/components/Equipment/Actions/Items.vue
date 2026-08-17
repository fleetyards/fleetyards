<script lang="ts">
export default {
  name: "EquipmentActionItems",
};
</script>

<script lang="ts" setup>
import {
  type Equipment,
  useDestroyEquipment,
  getEquipmentQueryKey,
} from "@/services/fyAdminApi";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  equipment: Equipment;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const invalidateEquipment = () =>
  queryClient.invalidateQueries({
    queryKey: getEquipmentQueryKey(),
  });

const destroyMutation = useDestroyEquipment({
  mutation: {
    onSettled: invalidateEquipment,
  },
});

const destroy = () => {
  if (!props.equipment.id) return;

  displayConfirm({
    text: t("messages.confirm.equipment.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.equipment.id! });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :to="{
      name: 'admin-equipment-edit',
      params: { id: props.equipment.id },
    }"
  >
    <i class="fa-duotone fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.delete')"
    @click="destroy"
    :tone="BtnTonesEnum.DANGER"
  >
    <i class="fa-duotone fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
