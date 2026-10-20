<script lang="ts">
export default {
  name: "HomePage",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import { FeatureFlagName } from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useSessionStore } from "@/frontend/stores/session";
import HomeLegacy from "@/frontend/components/Home/Legacy/index.vue";
import HomeLanding from "@/frontend/components/Home/Landing/index.vue";
import HomeDashboard from "@/frontend/components/Home/Dashboard/index.vue";

const { isAuthenticated } = storeToRefs(useSessionStore());

// No waiting on the flag list: it usually arrives prefetched with the page, in
// which case the query never fetches and `isFetched` stays false for good.
const { isFeatureEnabled } = useFeatures();

const redesigned = computed(() =>
  isFeatureEnabled(FeatureFlagName.HOMEPAGE_REDESIGN),
);
</script>

<template>
  <template v-if="redesigned">
    <HomeDashboard v-if="isAuthenticated" />
    <HomeLanding v-else />
  </template>
  <HomeLegacy v-else />
</template>
