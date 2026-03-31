<script lang="ts">
export default {
  name: "SettingsOauthApplicationsRouterView",
};
</script>

<script lang="ts" setup>
import FeatureGuard from "@/frontend/components/FeatureGuard.vue";
</script>

<template>
  <FeatureGuard feature="oauth-applications">
    <router-view />
  </FeatureGuard>
</template>
