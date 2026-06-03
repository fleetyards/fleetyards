<script lang="ts" setup>
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { routes as settingsRoutes } from "./settings/routes";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";

const sessionStore = useSessionStore();
const { isFeatureEnabled } = useFeatures();

const visibleRoutes = computed(() =>
  settingsRoutes.filter(
    (route) => !route.meta?.feature || isFeatureEnabled(route.meta.feature),
  ),
);
</script>

<template>
  <TabNavView
    :routes="visibleRoutes"
    :authenticated="sessionStore.isAuthenticated"
  />
</template>
