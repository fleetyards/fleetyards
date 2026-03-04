<script lang="ts" setup>
import { useManufacturer as useManufacturerQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: manufacturer, ...asyncStatus } = useManufacturerQuery(
  route.params.id as string,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :manufacturer="manufacturer" />
    </template>
  </AsyncData>
</template>
