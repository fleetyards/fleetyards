<script lang="ts">
export default {
  name: "VehicleActionItems",
};
</script>

<script lang="ts" setup>
import {
  type Vehicle,
  useDestroyVehicle,
  getVehiclesQueryKey,
} from "@/services/fyAdminApi";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";

type Props = {
  vehicle: Vehicle;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();
const { extend } = useBreadCrumbs();

const invalidateVehicles = () =>
  queryClient.invalidateQueries({
    queryKey: getVehiclesQueryKey(),
  });

const destroyMutation = useDestroyVehicle({
  mutation: {
    onSettled: invalidateVehicles,
  },
});

const destroy = () => {
  if (!props.vehicle.id) return;

  displayConfirm({
    text: t("messages.confirm.adminVehicle.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.vehicle.id! });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :to="
      extend({
        name: 'admin-vehicle-edit',
        params: { id: props.vehicle.id },
      })
    "
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
