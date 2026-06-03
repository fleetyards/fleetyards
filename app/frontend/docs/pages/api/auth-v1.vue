<script lang="ts">
export default {
  name: "AuthApiV1Layout",
};
</script>

<script lang="ts" setup>
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { routes } from "./auth-v1/routes";
</script>

<template>
  <TabNavView :routes="routes" authenticated />
</template>
