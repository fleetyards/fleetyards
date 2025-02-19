<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import { useModel as useModelQuery } from "@/services/fyApi";

const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { data: model, ...asyncStatus } = useModelQuery(slug.value);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :model="model" />
    </template>
  </AsyncData>
</template>
