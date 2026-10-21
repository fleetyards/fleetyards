<script lang="ts">
export default {
  name: "GameEventActionItems",
};
</script>

<script lang="ts" setup>
import {
  type GameEvent,
  useDestroyGameEvent,
  getGameEventsQueryKey,
} from "@/services/fyAdminApi";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";

type Props = {
  gameEvent: GameEvent;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm, displaySuccess } = useAppNotifications();
const queryClient = useQueryClient();

const invalidate = () =>
  queryClient.invalidateQueries({
    queryKey: getGameEventsQueryKey(),
  });

const destroyMutation = useDestroyGameEvent({
  mutation: {
    onSettled: invalidate,
  },
});

const destroy = () => {
  if (!props.gameEvent.id) return;

  displayConfirm({
    tone: AppConfirmTonesEnum.DANGER,
    text: t("messages.confirm.gameEvent.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.gameEvent.id! });
      displaySuccess({
        text: t("messages.gameEvent.destroyed"),
      });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :to="{
      name: 'admin-game-event-edit',
      params: { id: props.gameEvent.id },
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
