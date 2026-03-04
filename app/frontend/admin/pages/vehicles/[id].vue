<script lang="ts" setup>
import { useVehicle as useVehicleQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: vehicle, ...asyncStatus } = useVehicleQuery(
  route.params.id as string,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :vehicle="vehicle" />
    </template>
  </AsyncData>
</template>
