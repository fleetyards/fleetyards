<script lang="ts">
export default {
  name: "NotificationsDetail",
};
</script>

<script lang="ts" setup>
import AppIcon from "@/shared/components/AppIcon/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import NotificationDetail from "@/shared/components/Notifications/Detail/index.vue";
import { NOTIFICATION_LABELS } from "@/frontend/components/Notifications/labels";
import RecordActions from "@/frontend/components/Notifications/RecordActions/index.vue";
import {
  actionTestId,
  useNotificationActions,
} from "@/frontend/composables/useNotificationActions";
import { useI18n } from "@/shared/composables/useI18n";
import { type Notification } from "@/services/fyApi";

type Props = {
  notification?: Notification;
};

const props = withDefaults(defineProps<Props>(), {
  notification: undefined,
});

const emit = defineEmits<{
  close: [];
  unread: [];
  archive: [];
  unarchive: [];
  destroy: [];
  refresh: [];
}>();

const { t, l } = useI18n();

const { linksFor } = useNotificationActions();

const links = computed(() =>
  props.notification ? linksFor(props.notification) : [],
);
</script>

<template>
  <NotificationDetail
    :notification="notification"
    :type-label="
      notification
        ? t(`labels.notificationTypes.${notification.notificationType}`)
        : undefined
    "
    :labels="NOTIFICATION_LABELS"
    @close="emit('close')"
    @unread="emit('unread')"
    @archive="emit('archive')"
    @unarchive="emit('unarchive')"
    @destroy="emit('destroy')"
  >
    <template #footer="{ notification: open }">
      <!-- The way on. A row of its own rather than another icon beside archive
           and delete: what the notification is asking for should not have to
           compete with the housekeeping. -->
      <div
        v-if="links.length || open.record"
        class="notification-detail__cta"
        data-test="notification-detail-actions"
      >
        <RecordActions
          v-if="open.record"
          :notification="open"
          @done="emit('refresh')"
        />
        <Btn
          v-for="action in links"
          :key="action.key"
          :to="action.to"
          :href="action.href"
          :variant="action.primary ? undefined : BtnVariantsEnum.GHOST"
          :data-test="actionTestId(action.key)"
        >
          <AppIcon :icon="action.icon" />
          {{ t(`labels.notificationActions.${action.key}`) }}
        </Btn>
      </div>
    </template>

    <template #facts="{ notification: open }">
      <!-- Retention files a notification into the archive; the archive is what
           eventually deletes it. Each state names the date it is heading for. -->
      <div v-if="open.archived && open.deletesAt">
        <dt>{{ t("labels.notifications.deletesOn") }}</dt>
        <dd>{{ l(open.deletesAt) }}</dd>
      </div>
      <div v-else-if="!open.archived">
        <dt>{{ t("labels.notifications.archivesOn") }}</dt>
        <dd>{{ l(open.expiresAt) }}</dd>
      </div>
    </template>
  </NotificationDetail>
</template>

<style lang="scss" scoped>
.notification-detail__cta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 16px;
}
</style>
