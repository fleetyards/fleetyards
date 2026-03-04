<script lang="ts" setup>
import { useModelPaint as useModelPaintQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { data: modelPaint, ...asyncStatus } = useModelPaintQuery(
  route.params.id as string,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :model-paint="modelPaint" />
    </template>
  </AsyncData>
</template>
