<script lang="ts">
export default {
  name: "SettingsOauthApplicationsRouterView",
};
</script>

<script lang="ts" setup>
import FeatureGuard from "@/frontend/components/FeatureGuard.vue";
import { FeatureFlagName } from "@/services/fyApi";
</script>

<template>
  <FeatureGuard :feature="FeatureFlagName.OAUTH_APPLICATIONS">
    <router-view />
  </FeatureGuard>
</template>
