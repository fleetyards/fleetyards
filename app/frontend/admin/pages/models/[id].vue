<script lang="ts" setup>
import { useModelQueries } from "@/admin/composables/useModelQueries";
import AsyncData from "@/shared/components/AsyncData.vue";

const route = useRoute();

const { modelQuery } = useModelQueries();

const { data: model, ...asyncStatus } = modelQuery({
  id: route.params.id as string,
});
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :model="model" />
    </template>
  </AsyncData>
</template>
