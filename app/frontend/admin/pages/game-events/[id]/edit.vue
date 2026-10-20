<script lang="ts">
export default {
  name: "AdminGameEventEditPage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Heading from "@/shared/components/base/Heading/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import GameEventForm from "@/admin/components/GameEvents/Form/index.vue";
import {
  type GameEvent,
  type GameEventInput,
  useUpdateGameEvent,
  getGameEventsQueryKey,
  getGameEventQueryKey,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  gameEvent: GameEvent;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

const submitting = ref(false);

const updateMutation = useUpdateGameEvent({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({ queryKey: getGameEventsQueryKey() }),
        queryClient.invalidateQueries({
          queryKey: getGameEventQueryKey(props.gameEvent.id),
        }),
      ]);
    },
  },
});

const onSubmit = async (payload: GameEventInput) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.gameEvent.id, data: payload })
    .then(() => {
      displaySuccess({ text: t("messages.gameEvent.updated") });
    })
    .catch((error) => {
      console.error("Error updating game event:", error);
      displayAlert({ text: t("messages.gameEvent.updateFailed") });
    })
    .finally(() => {
      submitting.value = false;
    });
};

const handleCancel = async () => {
  await router.push(
    extend({ name: "admin-game-events", hash: `#${props.gameEvent.id}` }),
  );
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      {
        to: { name: 'admin-game-events' },
        label: t('headlines.admin.gameEvents.index'),
      },
    ]"
  />
  <Heading hero>{{ t("headlines.admin.gameEvents.edit") }}</Heading>
  <GameEventForm
    form-id="admin-game-event-edit-form"
    :game-event="gameEvent"
    :submitting="submitting"
    @submit="onSubmit"
    @cancel="handleCancel"
  />
</template>
