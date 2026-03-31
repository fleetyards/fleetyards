<script lang="ts" setup>
import { useFleet as useFleetQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: fleet, ...asyncStatus } = useFleetQuery(
  route.params.id as string,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :fleet="fleet" />
    </template>
  </AsyncData>
</template>
