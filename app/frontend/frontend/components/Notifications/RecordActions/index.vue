<script lang="ts">
export default {
  name: "NotificationsRecordActions",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { actionTestId } from "@/frontend/composables/useNotificationActions";
import {
  useNotificationRecordActions,
  type NotificationAction,
} from "@/frontend/composables/useNotificationRecordActions";
import { type Notification } from "@/services/fyApi";

type Props = {
  notification: Notification;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  done: [];
}>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const notification = computed(() => props.notification);

const { actions, externalLink, isLoading, isUnavailable, refresh } =
  useNotificationRecordActions(notification);

const running = ref<string>();

const run = async (action: NotificationAction) => {
  running.value = action.key;

  try {
    await action.run();
    displaySuccess({ text: t("messages.notifications.actionDone") });
    emit("done");
  } catch {
    // Most likely the record moved on between the load and the click, so the
    // honest response is to re-read it - the buttons then disappear on their
    // own rather than inviting a second failure.
    displayAlert({ text: t("messages.notifications.actionFailed") });
  } finally {
    running.value = undefined;
    await refresh();
  }
};
</script>

<template>
  <p
    v-if="isUnavailable"
    class="notification-record-actions__gone"
    data-test="notification-record-unavailable"
  >
    {{ t("labels.notificationActions.unavailable") }}
  </p>
  <template v-else-if="!isLoading">
    <Btn
      v-for="action in actions"
      :key="action.key"
      :tone="action.tone"
      :loading="running === action.key"
      :disabled="!!running"
      :data-test="actionTestId(action.key)"
      @click="run(action)"
    >
      <i :class="action.icon" />
      {{ t(`labels.notificationActions.${action.key}`) }}
    </Btn>
    <Btn
      v-if="externalLink"
      :href="externalLink.href"
      target="_blank"
      :variant="BtnVariantsEnum.GHOST"
      :data-test="actionTestId(externalLink.key)"
    >
      <i :class="externalLink.icon" />
      {{ t(`labels.notificationActions.${externalLink.key}`) }}
    </Btn>
  </template>
</template>

<style lang="scss" scoped>
.notification-record-actions__gone {
  margin: 0;
  align-self: center;
  color: $gray-lighter;
  font-size: 0.85em;
  font-style: italic;
}
</style>
