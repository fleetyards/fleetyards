<script lang="ts">
export default {
  name: "CommodityActionItems",
};
</script>

<script lang="ts" setup>
import {
  type Commodity,
  useDestroyCommodity,
  getCommoditiesQueryKey,
} from "@/services/fyAdminApi";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  commodity: Commodity;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const invalidateCommodities = () =>
  queryClient.invalidateQueries({
    queryKey: getCommoditiesQueryKey(),
  });

const destroyMutation = useDestroyCommodity({
  mutation: {
    onSettled: invalidateCommodities,
  },
});

const destroy = () => {
  if (!props.commodity.id) return;

  displayConfirm({
    text: t("messages.confirm.commodity.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.commodity.id! });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :to="{
      name: 'admin-commodity-edit',
      params: { id: props.commodity.id },
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
