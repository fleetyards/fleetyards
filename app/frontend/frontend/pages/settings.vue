<script lang="ts" setup>
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { routes as settingsRoutes } from "./settings/routes";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { usePendingFriendRequests } from "@/frontend/composables/usePendingFriendRequests";

const sessionStore = useSessionStore();
const { isFeatureEnabled } = useFeatures();

const visibleRoutes = computed(() =>
  settingsRoutes.filter(
    (route) => !route.meta?.feature || isFeatureEnabled(route.meta.feature),
  ),
);

const { count: pendingFriendRequests } = usePendingFriendRequests();

const badges = computed(() => ({
  "settings-friends": pendingFriendRequests.value,
}));
</script>

<template>
  <TabNavView
    :routes="visibleRoutes"
    :authenticated="sessionStore.isAuthenticated"
    :badges="badges"
  />
</template>
