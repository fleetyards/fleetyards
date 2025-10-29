<script lang="ts" setup>
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import { routes as settingsRoutes } from "./settings/routes";
import { useSessionStore } from "@/frontend/stores/session";

const sessionStore = useSessionStore();
</script>

<template>
  <TabNavView :routes="settingsRoutes">
    <template #nav>
      <TabNavViewItems
        :routes="settingsRoutes"
        :authenticated="sessionStore.isAuthenticated"
      />
    </template>
  </TabNavView>
</template>
