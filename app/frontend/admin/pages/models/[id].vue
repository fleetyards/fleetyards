<script lang="ts" setup>
import { useModel as useModelQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: model, ...asyncStatus } = useModelQuery(
  route.params.id as string,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :model="model" />
    </template>
  </AsyncData>
</template>
