<script lang="ts">
export default {
  name: "HomePage",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import HomeLanding from "@/frontend/components/Home/Landing/index.vue";
import HomeDashboard from "@/frontend/components/Home/Dashboard/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { FeatureFlagName } from "@/services/fyApi";

const { isAuthenticated } = storeToRefs(useSessionStore());

const { isFeatureEnabled } = useFeatures();

const showDashboard = computed(
  () =>
    isAuthenticated.value &&
    isFeatureEnabled(FeatureFlagName.HOMEPAGE_DASHBOARD),
);
</script>

<template>
  <HomeDashboard v-if="showDashboard" />
  <HomeLanding v-else />
</template>
