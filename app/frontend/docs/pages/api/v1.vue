<script lang="ts">
export default {
  name: "ApiV1Layout",
};
</script>

<script lang="ts" setup>
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { routes } from "./v1/routes";
</script>

<template>
  <TabNavView :routes="routes" authenticated />
</template>
