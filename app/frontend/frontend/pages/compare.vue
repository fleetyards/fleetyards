<script lang="ts">
export default {
  name: "ComparePage",
};
</script>

<script lang="ts" setup>
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { routes } from "@/frontend/pages/compare/routes";
import { useSessionStore } from "@/frontend/stores/session";

const sessionStore = useSessionStore();
</script>

<template>
  <TabNavView
    :routes="routes"
    :authenticated="sessionStore.isAuthenticated"
    horizontal
  />
</template>
