<script lang="ts">
export default {
  name: "SettingsFriendsRouterView",
};
</script>

<script lang="ts" setup>
import FeatureGuard from "@/frontend/components/FeatureGuard.vue";
import { FeatureFlagName } from "@/services/fyApi";
</script>

<template>
  <FeatureGuard :feature="FeatureFlagName.FRIENDS">
    <router-view />
  </FeatureGuard>
</template>
