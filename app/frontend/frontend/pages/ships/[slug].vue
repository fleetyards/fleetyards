<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import { useModelQueries } from "@/frontend/composables/useModelQueries";

const route = useRoute();

const slug = computed(() => route.params.slug as string);

const { modelQuery } = useModelQueries(slug.value);

const { data: model, ...asyncStatus } = modelQuery();
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <router-view :model="model" />
    </template>
  </AsyncData>
</template>
