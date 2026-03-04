<script lang="ts" setup>
import { useComponent as useComponentQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: component, ...asyncStatus } = useComponentQuery(
  route.params.id as string,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :component="component" />
    </template>
  </AsyncData>
</template>
