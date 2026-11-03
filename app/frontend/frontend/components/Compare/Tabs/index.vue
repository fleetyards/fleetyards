<script lang="ts">
export default {
  name: "CompareTabs",
};
</script>

<script lang="ts" setup>
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { routes } from "@/frontend/pages/compare/routes";
import { useSessionStore } from "@/frontend/stores/session";

const sessionStore = useSessionStore();
</script>

<template>
  <!-- The page itself is the parent route's view, so the strip renders no
       content of its own. -->
  <TabNavView
    :routes="routes"
    :authenticated="sessionStore.isAuthenticated"
    horizontal
    inline
  >
    <template #content />
  </TabNavView>
</template>
