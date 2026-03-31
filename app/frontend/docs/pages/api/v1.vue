<script lang="ts">
export default {
  name: "ApiV1Layout",
};
</script>

<script lang="ts" setup>
import TabNavView from "@/shared/components/TabNavView/index.vue";
import TabNavViewItems from "@/shared/components/TabNavView/Items/index.vue";
import { routes } from "./v1/routes";
</script>

<template>
  <TabNavView :routes="routes">
    <template #nav>
      <TabNavViewItems :routes="routes" :authenticated="true" />
    </template>
  </TabNavView>
</template>
