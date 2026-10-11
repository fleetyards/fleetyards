<script lang="ts">
export default {
  name: "AdminNotificationsDetail",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import NotificationDetail from "@/shared/components/Notifications/Detail/index.vue";
import { NOTIFICATION_LABELS } from "@/admin/components/Notifications/labels";
import { useI18n } from "@/shared/composables/useI18n";
import {
  hasSeverityLabel,
  severityPillVariant,
} from "@/admin/components/Notifications/severity";
import { type AdminNotification } from "@/services/fyAdminApi";

type Props = {
  notification?: AdminNotification;
};

withDefaults(defineProps<Props>(), {
  notification: undefined,
});

// No emits declared, so the page's listeners fall through to the shared pane.

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
    :labels="NOTIFICATION_LABELS"
  >
    <template #title="{ notification: open }">
      <span v-if="open.occurrences > 1" class="notification-detail__count">
        &times;{{ open.occurrences }}
      </span>
    </template>

    <template #meta="{ notification: open }">
      <BasePill
        v-if="hasSeverityLabel(open.severity)"
        :variant="severityPillVariant(open.severity)"
        uppercase
      >
        {{ t(`labels.adminNotifications.severities.${open.severity}`) }}
      </BasePill>
    </template>

    <template #actions="{ notification: open }">
      <Btn v-if="open.link" :to="open.link">
        <i class="fa-duotone fa-arrow-up-right-from-square" />
        {{ t("actions.open") }}
      </Btn>
    </template>

    <template #facts="{ notification: open }">
      <div v-if="open.occurrences > 1">
        <dt>{{ t("labels.adminNotifications.lastSeen") }}</dt>
        <dd>{{ l(open.lastOccurredAt) }}</dd>
      </div>
      <div>
        <dt>{{ t("labels.adminNotifications.expires") }}</dt>
        <dd>{{ l(open.expiresAt) }}</dd>
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
