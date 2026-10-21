<script lang="ts">
export default {
  name: "AdminGameEventCreatePage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Heading from "@/shared/components/base/Heading/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import GameEventForm from "@/admin/components/GameEvents/Form/index.vue";
import {
  type GameEventInput,
  useCreateGameEvent,
  getGameEventsQueryKey,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

const submitting = ref(false);

const createMutation = useCreateGameEvent({
  mutation: {
    onSettled: () => {
      void queryClient.invalidateQueries({
        queryKey: getGameEventsQueryKey(),
      });
    },
  },
});

const onSubmit = async (payload: GameEventInput) => {
  submitting.value = true;

  await createMutation
    .mutateAsync({ data: payload })
    .then(async () => {
      displaySuccess({ text: t("messages.gameEvent.created") });
      await router.push(extend({ name: "admin-game-events" }));
    })
    .catch((error) => {
      console.error("Error creating game event:", error);
      displayAlert({ text: t("messages.gameEvent.createFailed") });
    })
    .finally(() => {
      submitting.value = false;
    });
};

const handleCancel = async () => {
  await router.push(extend({ name: "admin-game-events" }));
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
  <Heading hero>{{ t("headlines.admin.gameEvents.new") }}</Heading>
  <GameEventForm
    form-id="admin-game-event-create-form"
    :submitting="submitting"
    @submit="onSubmit"
    @cancel="handleCancel"
  />
</template>
