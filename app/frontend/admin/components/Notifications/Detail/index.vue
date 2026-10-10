<script lang="ts">
export default {
  name: "AdminNotificationsDetail",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import NotificationDetail from "@/shared/components/Notifications/Detail/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  hasSeverityLabel,
  severityPillVariant,
} from "@/admin/components/Notifications/severity";
import { type AdminNotification } from "@/services/fyAdminApi";

// The pane's events (close, unread, archive, ...) fall through to the shared
// pane.
type Props = {
  notification?: AdminNotification;
};

withDefaults(defineProps<Props>(), {
  notification: undefined,
});

const { t, l } = useI18n();
</script>

<template>
  <!-- No severity tone: a framed red or amber edge around the whole pane shouts
       where the pill already says it, the same reason the rows dropped it. -->
  <NotificationDetail
    :notification="notification"
    :type-label="
      notification
        ? t(`labels.adminNotifications.types.${notification.notificationType}`)
        : undefined
    "
    scope="adminNotifications"
  >
    <template v-if="notification" #title>
      <span
        v-if="notification.occurrences > 1"
        class="notification-detail__count"
      >
        &times;{{ notification.occurrences }}
      </span>
    </template>

    <template v-if="notification" #meta>
      <BasePill
        v-if="hasSeverityLabel(notification.severity)"
        :variant="severityPillVariant(notification.severity)"
        uppercase
      >
        {{ t(`labels.adminNotifications.severities.${notification.severity}`) }}
      </BasePill>
    </template>

    <template v-if="notification" #actions>
      <Btn v-if="notification.link" :to="notification.link">
        <i class="fa-duotone fa-arrow-up-right-from-square" />
        {{ t("actions.open") }}
      </Btn>
    </template>

    <template v-if="notification" #facts>
      <div v-if="notification.occurrences > 1">
        <dt>{{ t("labels.adminNotifications.lastSeen") }}</dt>
        <dd>{{ l(notification.lastOccurredAt) }}</dd>
      </div>
      <div>
        <dt>{{ t("labels.adminNotifications.expires") }}</dt>
        <dd>{{ l(notification.expiresAt) }}</dd>
      </div>
    </template>
  </NotificationDetail>
</template>

<style lang="scss" scoped>
.notification-detail__count {
  color: $gray-lighter;
  font-size: 0.8em;
}
</style>
