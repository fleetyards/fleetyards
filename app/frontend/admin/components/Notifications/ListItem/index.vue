<script lang="ts">
export default {
  name: "AdminNotificationsListItem",
};
</script>

<script lang="ts" setup>
import BasePill from "@/shared/components/base/Pill/index.vue";
import NotificationListItem from "@/shared/components/Notifications/ListItem/index.vue";
import type { ComponentExposed } from "vue-component-type-helpers";
import { NOTIFICATION_LABELS } from "@/admin/components/Notifications/labels";
import { useI18n } from "@/shared/composables/useI18n";
import {
  hasSeverityLabel,
  severityPillVariant,
} from "@/admin/components/Notifications/severity";
import { type AdminNotification } from "@/services/fyAdminApi";

type Props = {
  notification: AdminNotification;
  selected?: boolean;
  selectable?: boolean;
  checked?: boolean;
};

withDefaults(defineProps<Props>(), {
  selected: false,
  selectable: false,
  checked: false,
});

// No emits declared, so the page's listeners fall through to the shared row.

const { t } = useI18n();

const row = ref<ComponentExposed<typeof NotificationListItem>>();

defineExpose({ focus: () => row.value?.focus() });
</script>

<template>
  <!-- Severity used to colour the row's edge, which made a list of imports read
       as an alarm; the pill carries it now. -->
  <NotificationListItem
    ref="row"
    :notification="notification"
    :type-label="
      t(`labels.adminNotifications.types.${notification.notificationType}`)
    "
    :labels="NOTIFICATION_LABELS"
    :selected="selected"
    :selectable="selectable"
    :checked="checked"
  >
    <template #title="{ notification: entry }">
      <span v-if="entry.occurrences > 1" class="notification-item__count">
        &times;{{ entry.occurrences }}
      </span>
    </template>
    <template #meta="{ notification: entry }">
      <BasePill
        v-if="hasSeverityLabel(entry.severity)"
        :variant="severityPillVariant(entry.severity)"
        uppercase
      >
        {{ t(`labels.adminNotifications.severities.${entry.severity}`) }}
      </BasePill>
    </template>
  </NotificationListItem>
</template>

<style lang="scss" scoped>
.notification-item__count {
  color: $gray-lighter;
  font-size: 0.85em;
}
</style>
