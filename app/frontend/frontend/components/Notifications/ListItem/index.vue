<script lang="ts">
export default {
  name: "NotificationsListItem",
};
</script>

<script lang="ts" setup>
import AppIcon from "@/shared/components/AppIcon/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import NotificationListItem from "@/shared/components/Notifications/ListItem/index.vue";
import type { ComponentExposed } from "vue-component-type-helpers";
import { NOTIFICATION_LABELS } from "@/frontend/components/Notifications/labels";
import { useI18n } from "@/shared/composables/useI18n";
import { useNotificationActions } from "@/frontend/composables/useNotificationActions";
import { type Notification } from "@/services/fyApi";

type Props = {
  notification: Notification;
  selected?: boolean;
  selectable?: boolean;
  checked?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  selected: false,
  selectable: false,
  checked: false,
});

// No emits declared, so the page's listeners fall through to the shared row.

const { t } = useI18n();

const { primaryLink } = useNotificationActions();

const primary = computed(() => primaryLink(props.notification));

const row = ref<ComponentExposed<typeof NotificationListItem>>();

defineExpose({ focus: () => row.value?.focus() });
</script>

<template>
  <NotificationListItem
    ref="row"
    :notification="notification"
    :type-label="t(`labels.notificationTypes.${notification.notificationType}`)"
    :labels="NOTIFICATION_LABELS"
    :selected="selected"
    :selectable="selectable"
    :checked="checked"
  >
    <template #actions>
      <!-- Only the way on, and only as an icon: the row has to survive on a
           phone, and anything the reader has to weigh up belongs in the
           reading pane, which is the surface that knows the current state. -->
      <Btn
        v-if="primary"
        v-tooltip="t(`labels.notificationActions.${primary.key}`)"
        :aria-label="t(`labels.notificationActions.${primary.key}`)"
        :to="primary.to"
        data-test="notification-item-open"
      >
        <AppIcon :icon="primary.icon" />
      </Btn>
    </template>
  </NotificationListItem>
</template>
