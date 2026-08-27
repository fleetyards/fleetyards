<script lang="ts">
export default {
  name: "FrontendNotificationsNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNotificationsUnreadCount as useNotificationsUnreadCountQuery } from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { storeToRefs } from "pinia";

type Props = {
  iconOnly?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  iconOnly: false,
});

const { t } = useI18n();

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

// The cable subscription in `useUpdates` invalidates this on every arriving
// notification; the interval only covers what expired or was read elsewhere.
const { data: unreadCount } = useNotificationsUnreadCountQuery({
  query: { enabled: isAuthenticated, refetchInterval: 60_000 },
});

const badge = computed(() => unreadCount.value?.count || 0);
</script>

<template>
  <NavItem
    menu-key="notifications"
    :label="props.iconOnly ? undefined : t('nav.notifications')"
    icon="fa-duotone fa-bell"
    :badge="badge"
    :to="{ name: 'notifications' }"
  />
</template>
