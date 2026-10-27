<script lang="ts">
export default {
  name: "RaffleActionItems",
};
</script>

<script lang="ts" setup>
import {
  type Raffle,
  useDestroyRaffle,
  getRafflesQueryKey,
} from "@/services/fyAdminApi";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";

type Props = {
  raffle: Raffle;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm, displaySuccess } = useAppNotifications();
const queryClient = useQueryClient();

const destroyMutation = useDestroyRaffle({
  mutation: {
    onSettled: () =>
      queryClient.invalidateQueries({ queryKey: getRafflesQueryKey() }),
  },
});

const destroy = () => {
  displayConfirm({
    tone: AppConfirmTonesEnum.DANGER,
    text: t("messages.confirm.raffle.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.raffle.id });
      displaySuccess({ text: t("messages.raffle.destroyed") });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.raffle.entries')"
    :to="{ name: 'admin-raffle-entries', params: { id: props.raffle.id } }"
  >
    <i class="fa-duotone fa-ticket" />
    <span v-if="withLabels">{{ t("actions.raffle.entries") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :to="{ name: 'admin-raffle-edit', params: { id: props.raffle.id } }"
  >
    <i class="fa-duotone fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-if="!props.raffle.drawnAt"
    v-tooltip="!withLabels && t('actions.delete')"
    :tone="BtnTonesEnum.DANGER"
    @click="destroy"
  >
    <i class="fa-duotone fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
