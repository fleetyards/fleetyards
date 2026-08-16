<script lang="ts">
export default {
  name: "AdminNotificationsNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useRouter } from "vue-router";
import {
  useAdminNotifications as useAdminNotificationsQuery,
  useAdminNotificationsUnreadCount as useAdminNotificationsUnreadCountQuery,
  readAllAdminNotifications,
  type AdminNotification,
} from "@/services/fyAdminApi";
import { useAdminNotificationUpdates } from "@/admin/composables/useAdminNotificationUpdates";

const RECENT_LIMIT = 5;

type Props = {
  authenticated?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  authenticated: false,
});

const { t } = useI18n();

const router = useRouter();

const enabled = computed(() => props.authenticated);

const { invalidate } = useAdminNotificationUpdates(enabled);

const { data: unreadCount } = useAdminNotificationsUnreadCountQuery({
  query: { enabled, refetchInterval: 60_000 },
});

const recentParams = computed(() => ({
  perPage: String(RECENT_LIMIT),
  q: { readAtNull: true },
}));

const { data: recentNotifications } = useAdminNotificationsQuery(recentParams, {
  query: { enabled },
});

const recent = computed(() => recentNotifications.value?.items || []);

const badge = computed(() => unreadCount.value?.count || 0);

const open = async (notification: AdminNotification) => {
  if (notification.link) {
    await router.push(notification.link);
    return;
  }

  await router.push({ name: "admin-notifications" });
};

const markAllRead = async () => {
  await readAllAdminNotifications();

  invalidate();
};
</script>

<template>
  <NavItem
    menu-key="admin-notifications"
    :label="t('nav.admin.notifications.index')"
    icon="fa-duotone fa-bell"
    :badge="badge"
    submenu-direction="up"
  >
    <template #submenu>
      <li v-if="!recent.length" class="admin-notifications__empty">
        {{ t("labels.adminNotifications.empty") }}
      </li>
      <NavItem
        v-for="notification in recent"
        :key="notification.id"
        :menu-key="notification.id"
        :label="notification.title"
        :icon="notification.icon"
        :action="() => open(notification)"
      />
      <NavItem
        v-if="badge"
        menu-key="admin-notifications-read-all"
        :label="t('labels.adminNotifications.readAll')"
        icon="fa-duotone fa-check-double"
        :action="markAllRead"
      />
      <NavItem
        menu-key="admin-notifications-all"
        :label="t('labels.adminNotifications.showAll')"
        icon="fa-duotone fa-list"
        :to="{ name: 'admin-notifications' }"
      />
    </template>
  </NavItem>
</template>

<style lang="scss" scoped>
.admin-notifications__empty {
  padding: 10px 15px;
  color: $gray-lighter;
  font-size: 0.9em;
}
</style>
