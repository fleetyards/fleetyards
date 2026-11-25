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

const { isAuthenticated } = storeToRefs(useSessionStore());
</script>

<template>
  <HomeDashboard v-if="isAuthenticated" />
  <HomeLanding v-else />
</template>
