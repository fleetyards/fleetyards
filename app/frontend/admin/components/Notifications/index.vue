<script lang="ts">
export default {
  name: "AdminNotificationsNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAdminNotificationsUnreadCount as useAdminNotificationsUnreadCountQuery } from "@/services/fyAdminApi";
import { useAdminNotificationUpdates } from "@/admin/composables/useAdminNotificationUpdates";

type Props = {
  authenticated?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  authenticated: false,
});

const { t } = useI18n();

const route = useRoute();

// This row is written by hand rather than rendered from the routes, so the
// `activeRoute` convention AppNavigationItems applies has to be read here too.
// Announcements is the section that points at it: hidden from the nav, reached
// from the notifications page, and with nothing else to light up while it is
// open.
const active = computed(
  () => route.meta?.activeRoute === "admin-notifications",
);

const enabled = computed(() => props.authenticated);

useAdminNotificationUpdates(enabled);

const { data: unreadCount } = useAdminNotificationsUnreadCountQuery({
  query: { enabled, refetchInterval: 60_000 },
});

const badge = computed(() => unreadCount.value?.count || 0);
</script>

<template>
  <NavItem
    menu-key="admin-notifications"
    :label="t('nav.admin.notifications.index')"
    icon="fa-duotone fa-bell"
    :badge="badge"
    :active="active"
    :to="{ name: 'admin-notifications' }"
  />
</template>
