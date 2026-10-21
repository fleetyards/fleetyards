<script lang="ts">
export default {
  name: "HomePage",
};
</script>

<script lang="ts" setup>
import { FeatureFlagName } from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";
import HomeLegacy from "@/frontend/components/Home/Legacy/index.vue";
import HomeLanding from "@/frontend/components/Home/Landing/index.vue";

// No waiting on the flag list: it usually arrives prefetched with the page, in
// which case the query never fetches and `isFetched` stays false for good.
const { isFeatureEnabled } = useFeatures();

const redesigned = computed(() =>
  isFeatureEnabled(FeatureFlagName.HOMEPAGE_REDESIGN),
);
</script>

<template>
  <!-- Pilots get the landing page too until their own version is designed. -->
  <HomeLanding v-if="redesigned" />
  <HomeLegacy v-else />
</template>
