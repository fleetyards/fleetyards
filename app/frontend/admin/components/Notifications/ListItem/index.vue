<script lang="ts">
export default {
  name: "AdminNotificationsListItem",
};
</script>

<script lang="ts" setup>
import BasePill from "@/shared/components/base/Pill/index.vue";
import NotificationListItem from "@/shared/components/Notifications/ListItem/index.vue";
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

const emit = defineEmits<{
  select: [];
  toggle: [checked: boolean];
  archive: [];
  unarchive: [];
  destroy: [];
  previous: [];
  next: [];
}>();

const { t } = useI18n();

const row = ref<InstanceType<typeof NotificationListItem>>();

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
    scope="adminNotifications"
    :selected="selected"
    :selectable="selectable"
    :checked="checked"
    @select="emit('select')"
    @toggle="emit('toggle', $event)"
    @archive="emit('archive')"
    @unarchive="emit('unarchive')"
    @destroy="emit('destroy')"
    @previous="emit('previous')"
    @next="emit('next')"
  >
    <template #title>
      <span
        v-if="notification.occurrences > 1"
        class="notification-item__count"
      >
        &times;{{ notification.occurrences }}
      </span>
    </template>
    <template #meta>
      <BasePill
        v-if="hasSeverityLabel(notification.severity)"
        :variant="severityPillVariant(notification.severity)"
        uppercase
      >
        {{ t(`labels.adminNotifications.severities.${notification.severity}`) }}
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
